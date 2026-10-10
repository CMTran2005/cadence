import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/parsed_receipt_draft.dart';

class HeuristicParserService {
  static final List<String> _totalKeywords = [
    'tổng cộng',
    'tong cong',
    'thành tiền',
    'thanh tien',
    'tổng thanh toán',
    'tong thanh toan',
    'thanh toán',
    'thanh toan',
    'cộng tiền hàng',
    'cong tien hang',
    'phải trả',
    'phai tra',
    'tiền mặt',
    'tien mat',
    'total amount',
    'grand total',
    'total',
    'amount due',
    'net total',
  ];

  static final List<String> _merchantBlacklist = [
    'hóa đơn',
    'hoa don',
    'phiếu tính tiền',
    'phieu tinh tien',
    'phiếu thanh toán',
    'phieu thanh toan',
    'receipt',
    'bill',
    'invoice',
    'vat',
    'cộng hòa xã hội',
    'độc lập tự do',
    'mã số thuế',
    'mst',
    'tel',
    'sđt',
    'hotline',
    'địa chỉ',
    'dia chi',
    'welcome',
    'xin chào',
    'cảm ơn',
    'cam on',
    'thank you',
    'thu ngân',
    'khách hàng',
    'bàn số',
    'ngày in',
  ];

  ParsedReceiptDraft parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double totalAmount = _extractTotalAmount(lines, rawText);
    DateTime transactionDate = _extractDate(lines, rawText);
    String merchant = _extractMerchant(lines);
    CategoryType category = _classifyCategory(rawText, merchant);

    double confidence = 0.5;
    if (totalAmount > 0) confidence += 0.25;
    if (merchant.isNotEmpty && merchant != 'Cửa hàng không tên') confidence += 0.15;
    if (category != CategoryType.other) confidence += 0.1;

    return ParsedReceiptDraft(
      merchant: merchant,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      suggestedCategory: category,
      confidenceScore: confidence.clamp(0.0, 1.0),
      rawText: rawText,
      imagePath: imagePath,
      extractedLines: lines,
    );
  }

  double _extractTotalAmount(List<String> lines, String fullText) {
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      for (final keyword in _totalKeywords) {
        if (lineLower.contains(keyword)) {
          final amt = _extractNumberFromLine(line);
          if (amt > 0) return amt;

          if (i + 1 < lines.length) {
            final nextAmt = _extractNumberFromLine(lines[i + 1]);
            if (nextAmt > 0) return nextAmt;
          }
        }
      }
    }

    // Fallback: search largest number in text with currency format
    double maxAmount = 0.0;
    final regex = RegExp(r'\b\d{1,3}(?:[.,]\d{3})+(?:\s*(?:đ|vnd|vnđ))?\b', caseSensitive: false);
    for (final match in regex.allMatches(fullText)) {
      final val = CurrencyFormatter.parseAmount(match.group(0)!);
      if (val > maxAmount && val < 500000000) {
        maxAmount = val;
      }
    }

    return maxAmount;
  }

  double _extractNumberFromLine(String line) {
    final regex = RegExp(r'\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?\b');
    final matches = regex.allMatches(line).toList();
    if (matches.isEmpty) return 0.0;

    for (int i = matches.length - 1; i >= 0; i--) {
      final numStr = matches[i].group(0)!;
      final parsed = CurrencyFormatter.parseAmount(numStr);
      if (parsed >= 1000) return parsed;
    }
    return 0.0;
  }

  DateTime _extractDate(List<String> lines, String fullText) {
    // Regex for dd/MM/yyyy or dd-MM-yyyy
    final dateRegex = RegExp(r'\b(\d{1,2})[/\.-](\d{1,2})[/\.-](\d{2,4})\b');
    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        try {
          int day = int.parse(match.group(1)!);
          int month = int.parse(match.group(2)!);
          int year = int.parse(match.group(3)!);
          if (year < 100) year += 2000;

          if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  String _extractMerchant(List<String> lines) {
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      bool isBlacklisted = false;
      for (final black in _merchantBlacklist) {
        if (lineLower.contains(black)) {
          isBlacklisted = true;
          break;
        }
      }

      if (isBlacklisted) continue;
      if (RegExp(r'^\d+$').hasMatch(line)) continue;
      if (line.length < 3) continue;

      // Clean extra characters
      String cleaned = line.replaceAll(RegExp(r'[#*=-]'), '').trim();
      if (cleaned.isNotEmpty) return cleaned;
    }

    return 'Cửa hàng không tên';
  }

  CategoryType _classifyCategory(String fullText, String merchant) {
    final text = '$merchant $fullText'.toLowerCase();

    if (text.contains('winmart') ||
        text.contains('circle k') ||
        text.contains('coffee') ||
        text.contains('cà phê') ||
        text.contains('highlands') ||
        text.contains('phúc long') ||
        text.contains('bánh mì') ||
        text.contains('nhà hàng') ||
        text.contains('quán ăn') ||
        text.contains('bún') ||
        text.contains('phở') ||
        text.contains('food')) {
      return CategoryType.food;
    }

    if (text.contains('shopee') ||
        text.contains('lazada') ||
        text.contains('tiki') ||
        text.contains('quần áo') ||
        text.contains('thời trang') ||
        text.contains('shopping')) {
      return CategoryType.shopping;
    }

    if (text.contains('petrolimex') ||
        text.contains('xăng') ||
        text.contains('grab') ||
        text.contains('be') ||
        text.contains('vé xe') ||
        text.contains('taxi')) {
      return CategoryType.transport;
    }

    if (text.contains('tiền điện') ||
        text.contains('tiền nước') ||
        text.contains('viettel') ||
        text.contains('vinaphone') ||
        text.contains('vnpt') ||
        text.contains('internet')) {
      return CategoryType.bills;
    }

    if (text.contains('sách') ||
        text.contains('nhà sách') ||
        text.contains('fahasa') ||
        text.contains('học phí') ||
        text.contains('khoá học')) {
      return CategoryType.education;
    }

    if (text.contains('phim') ||
        text.contains('cgv') ||
        text.contains('lotte') ||
        text.contains('game') ||
        text.contains('cinema')) {
      return CategoryType.entertainment;
    }

    if (text.contains('nhà thuốc') ||
        text.contains('pharmacity') ||
        text.contains('long châu') ||
        text.contains('bệnh viện') ||
        text.contains('khám bệnh')) {
      return CategoryType.health;
    }

    return CategoryType.other;
  }
}
