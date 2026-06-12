String formatRupee(double amount) {
  // Convert to string with 2 decimal places
  String numStr = amount.toStringAsFixed(2);
  
  // Split into integer and decimal parts
  List<String> parts = numStr.split('.');
  String intPart = parts[0];
  String decPart = parts[1];
  
  // Indian number format: last 3 digits, then groups of 2
  String result = '';
  int len = intPart.length;
  
  if (len <= 3) {
    result = intPart;
  } else {
    // Last 3 digits
    result = intPart.substring(len - 3);
    int remaining = len - 3;
    
    // Groups of 2 from right to left
    while (remaining > 0) {
      int start = remaining >= 2 ? remaining - 2 : 0;
      result = intPart.substring(start, remaining) + ',' + result;
      remaining = start;
    }
  }
  
  return '₹$result.$decPart';
}