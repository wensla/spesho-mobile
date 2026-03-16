<?php
require_once __DIR__ . '/../vendor/autoload.php';

use Fpdf\Fpdf;

class SpeshoPdf extends Fpdf {
    private string $report_title = '';
    private string $subtitle     = '';

    public function setReportTitle(string $t, string $s = ''): void {
        $this->report_title = $t;
        $this->subtitle     = $s;
    }

    public function Header(): void {
        $this->SetFont('Helvetica', 'B', 14);
        $this->Cell(0, 8, 'SPESHO PRODUCTS MANAGEMENT SYSTEM', 0, 1, 'C');
        $this->SetFont('Helvetica', 'B', 12);
        $this->Cell(0, 7, $this->report_title, 0, 1, 'C');
        if ($this->subtitle) {
            $this->SetFont('Helvetica', '', 9);
            $this->SetTextColor(120, 120, 120);
            $this->Cell(0, 5, $this->subtitle, 0, 1, 'C');
            $this->SetTextColor(0);
        }
        $this->SetFont('Helvetica', '', 8);
        $this->SetTextColor(150);
        $this->Cell(0, 5, 'Generated: ' . date('Y-m-d H:i'), 0, 1, 'C');
        $this->SetTextColor(0);
        $this->Ln(3);
    }

    public function Footer(): void {
        $this->SetY(-15);
        $this->SetFont('Helvetica', 'I', 8);
        $this->SetTextColor(150);
        $this->Cell(0, 10, 'Page ' . $this->PageNo(), 0, 0, 'C');
    }

    public function table_header(array $headers, array $widths): void {
        $this->SetFillColor(26, 35, 126);
        $this->SetTextColor(255);
        $this->SetFont('Helvetica', 'B', 8);
        foreach ($headers as $i => $h) {
            $this->Cell($widths[$i], 7, $h, 1, 0, 'C', true);
        }
        $this->Ln();
        $this->SetTextColor(0);
        $this->SetFont('Helvetica', '', 8);
    }

    public function table_row(array $values, array $widths, bool $fill = false): void {
        if ($fill) $this->SetFillColor(245, 245, 245);
        foreach ($values as $i => $v) {
            $this->Cell($widths[$i], 6, (string)$v, 1, 0, 'L', $fill);
        }
        $this->Ln();
    }

    public function summary_row(string $label, string $value, array $widths): void {
        $this->SetFont('Helvetica', 'B', 8);
        $this->SetFillColor(227, 242, 253);
        $total_w = array_sum($widths);
        $last_w  = end($widths);
        $this->Cell($total_w - $last_w, 6, $label, 1, 0, 'R', true);
        $this->Cell($last_w, 6, $value, 1, 1, 'R', true);
        $this->SetFont('Helvetica', '', 8);
    }
}

function generate_sales_pdf(array $sales, string $title, string $subtitle = ''): string {
    $pdf = new SpeshoPdf('L', 'mm', 'A4');
    $pdf->setReportTitle($title, $subtitle);
    $pdf->SetMargins(10, 20, 10);
    $pdf->SetAutoPageBreak(true, 20);
    $pdf->AddPage();

    $headers = ['#', 'Date', 'Product', 'Qty', 'Price', 'Discount', 'Total', 'Sold By'];
    $widths  = [8, 22, 60, 18, 28, 28, 30, 30];

    $pdf->table_header($headers, $widths);

    $grand_total    = 0;
    $grand_discount = 0;
    foreach ($sales as $i => $s) {
        $pdf->table_row([
            $i + 1,
            $s['date'] ?? '',
            $s['product_name'] ?? '',
            number_format((float)($s['quantity'] ?? 0), 0),
            number_format((float)($s['price'] ?? 0), 2),
            number_format((float)($s['discount'] ?? 0), 2),
            number_format((float)($s['total'] ?? 0), 2),
            $s['sold_by_name'] ?? '',
        ], $widths, $i % 2 === 1);
        $grand_total    += (float)($s['total'] ?? 0);
        $grand_discount += (float)($s['discount'] ?? 0);
    }
    $pdf->summary_row('TOTAL DISCOUNTS', number_format($grand_discount, 2), $widths);
    $pdf->summary_row('GRAND TOTAL', number_format($grand_total, 2), $widths);

    return $pdf->Output('S');
}

function generate_stock_pdf(array $movements, string $title, string $subtitle = ''): string {
    $pdf = new SpeshoPdf('L', 'mm', 'A4');
    $pdf->setReportTitle($title, $subtitle);
    $pdf->SetMargins(10, 20, 10);
    $pdf->SetAutoPageBreak(true, 20);
    $pdf->AddPage();

    $headers = ['#', 'Date', 'Product', 'Stock In', 'Stock Out', 'Unit Price', 'Type'];
    $widths  = [8, 25, 90, 25, 25, 30, 25];

    $pdf->table_header($headers, $widths);
    foreach ($movements as $i => $m) {
        $pdf->table_row([
            $i + 1,
            $m['date'] ?? '',
            $m['product_name'] ?? '',
            number_format((float)($m['quantity_in'] ?? 0), 0),
            number_format((float)($m['quantity_out'] ?? 0), 0),
            $m['unit_price'] !== null ? number_format((float)$m['unit_price'], 2) : '-',
            strtoupper($m['movement_type'] ?? ''),
        ], $widths, $i % 2 === 1);
    }
    return $pdf->Output('S');
}

function generate_stock_balance_pdf(array $balances): string {
    $pdf = new SpeshoPdf();
    $pdf->setReportTitle('Stock Balance Report');
    $pdf->SetMargins(15, 20, 15);
    $pdf->SetAutoPageBreak(true, 20);
    $pdf->AddPage();

    $headers = ['#', 'Product', 'Unit Price', 'Current Stock', 'Stock Value'];
    $widths  = [10, 80, 35, 35, 35];

    $pdf->table_header($headers, $widths);
    $total_value = 0;
    foreach ($balances as $i => $b) {
        $pdf->table_row([
            $i + 1,
            $b['product_name'] ?? '',
            number_format((float)($b['unit_price'] ?? 0), 2),
            number_format((float)($b['current_stock'] ?? 0), 2),
            number_format((float)($b['stock_value'] ?? 0), 2),
        ], $widths, $i % 2 === 1);
        $total_value += (float)($b['stock_value'] ?? 0);
    }
    $pdf->summary_row('TOTAL VALUE', number_format($total_value, 2), $widths);
    return $pdf->Output('S');
}
