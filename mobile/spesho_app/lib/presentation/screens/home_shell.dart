import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/stock/stock_in_screen.dart';
import '../screens/stock/stock_balance_screen.dart';
import '../screens/sales/sales_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/users/users_screen.dart';
import '../screens/debts/debts_screen.dart';
import '../screens/shops/shops_screen.dart';
import '../../core/theme/app_theme.dart';

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Super Admin: all modules + Shops management
  static const _superAdminNavItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.store_rounded, 'Shops'),
    _NavItem(Icons.inventory_2_rounded, 'Products'),
    _NavItem(Icons.point_of_sale_rounded, 'Sales'),
    _NavItem(Icons.add_box_rounded, 'Stock In'),
    _NavItem(Icons.warehouse_rounded, 'Stock'),
    _NavItem(Icons.bar_chart_rounded, 'Reports'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Debts'),
    _NavItem(Icons.people_rounded, 'Users'),
  ];

  // Manager: shop-level operations
  static const _managerNavItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard'),
    _NavItem(Icons.inventory_2_rounded, 'Products'),
    _NavItem(Icons.point_of_sale_rounded, 'Sales'),
    _NavItem(Icons.add_box_rounded, 'Stock In'),
    _NavItem(Icons.warehouse_rounded, 'Stock'),
    _NavItem(Icons.bar_chart_rounded, 'Reports'),
    _NavItem(Icons.account_balance_wallet_rounded, 'Debts'),
    _NavItem(Icons.people_rounded, 'Users'),
  ];

  // Seller: record sales + view stock
  static const _sellerNavItems = [
    _NavItem(Icons.point_of_sale_rounded, 'Sales'),
    _NavItem(Icons.warehouse_rounded, 'Stock'),
  ];

  static const _superAdminPages = [
    DashboardScreen(),
    ShopsScreen(),
    ProductsScreen(),
    SalesScreen(),
    StockInScreen(),
    StockBalanceScreen(),
    ReportsScreen(),
    DebtsScreen(),
    UsersScreen(),
  ];

  static const _managerPages = [
    DashboardScreen(),
    ProductsScreen(),
    SalesScreen(),
    StockInScreen(),
    StockBalanceScreen(),
    ReportsScreen(),
    DebtsScreen(),
    UsersScreen(),
  ];

  static const _sellerPages = [
    SalesScreen(),
    StockBalanceScreen(),
  ];

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 700;

    final List<_NavItem> navItems;
    final List<Widget> pages;

    if (auth.isSuperAdmin) {
      navItems = _superAdminNavItems;
      pages = _superAdminPages;
    } else if (auth.isManager) {
      navItems = _managerNavItems;
      pages = _managerPages;
    } else {
      navItems = _sellerNavItems;
      pages = _sellerPages;
    }

    final safeIndex = _index.clamp(0, pages.length - 1);

    if (isDesktop) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Row(
          children: [
            _Sidebar(
              navItems: navItems,
              selectedIndex: safeIndex,
              user: user,
              roleLabel: user?.roleLabel ?? '',
              onSelect: (i) => setState(() => _index = i),
              onLogout: _logout,
            ),
            Expanded(
              child: IndexedStack(index: safeIndex, children: pages),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF131921), Color(0xFF1A2535)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.grain_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Spesho', style: GoogleFonts.poppins(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.5,
              )),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('PRO', style: GoogleFonts.poppins(
                  color: AppTheme.accent, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1,
                )),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFF8A99AF)),
              tooltip: 'Sign Out',
              onPressed: _logout,
            ),
          ],
        ),
        body: IndexedStack(index: safeIndex, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: safeIndex,
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: AppTheme.textSecondary,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedLabelStyle: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
              items: navItems.map((n) => BottomNavigationBarItem(
                icon: Icon(n.icon),
                activeIcon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(n.icon, color: AppTheme.primary),
                ),
                label: n.label,
              )).toList(),
              onTap: (i) => setState(() => _index = i),
            ),
          ),
        ),
        drawer: _MobileDrawer(
          navItems: navItems,
          selectedIndex: safeIndex,
          user: user,
          roleLabel: user?.roleLabel ?? '',
          onSelect: (i) {
            setState(() => _index = i);
            Navigator.pop(context);
          },
          onLogout: _logout,
        ),
      );
    }
  }
}

// ── Desktop Sidebar ──────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final dynamic user;
  final String roleLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.user,
    required this.roleLabel,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.grain_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Spesho', style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                    )),
                    Text('Management System', style: GoogleFonts.poppins(
                      color: const Color(0xFF8A99AF), fontSize: 9, fontWeight: FontWeight.w400,
                    )),
                  ]),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2E3A4E), height: 1),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'NAVIGATION',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4A5568),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                itemBuilder: (_, i) => _SidebarItem(
                  item: navItems[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              ),
            ),
            const Divider(color: Color(0xFF2E3A4E), height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    radius: 18,
                    child: Text(
                      (user?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(roleLabel, style: const TextStyle(color: Color(0xFF8A99AF), fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFF8A99AF), size: 20),
                    tooltip: 'Sign Out',
                    onPressed: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AppTheme.sidebarHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              gradient: selected
                  ? LinearGradient(
                      colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.primary.withValues(alpha: 0.10)],
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: selected ? Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1) : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: selected ? AppTheme.primaryGradient : null,
                      color: selected ? null : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 18, color: selected ? Colors.white : const Color(0xFF8A99AF)),
                  ),
                  const SizedBox(width: 10),
                  Text(item.label,
                    style: GoogleFonts.poppins(
                      color: selected ? Colors.white : const Color(0xFF8A99AF),
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mobile Drawer ────────────────────────────────────────────────────────────

class _MobileDrawer extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final dynamic user;
  final String roleLabel;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _MobileDrawer({
    required this.navItems,
    required this.selectedIndex,
    required this.user,
    required this.roleLabel,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.sidebarBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grain, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spesho', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(roleLabel, style: const TextStyle(color: Color(0xFF8A99AF), fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF2E3A4E), height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: navItems.length,
                itemBuilder: (_, i) => _SidebarItem(
                  item: navItems[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelect(i),
                ),
              ),
            ),
            const Divider(color: Color(0xFF2E3A4E), height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFF8A99AF)),
              title: const Text('Sign Out', style: TextStyle(color: Color(0xFF8A99AF))),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}
