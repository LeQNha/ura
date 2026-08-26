/// Các hàm thuần túy (pure function) cho Urban Scanner — tách riêng
/// khỏi UI để dễ kiểm soát logic, không phụ thuộc Flutter widget.

/// Chênh lệch góc ngắn nhất từ [from] đến [to] (độ), luôn trả về giá
/// trị trong khoảng -180..180. Ví dụ: from=350, to=10 → trả về 20 (chứ
/// không phải -340), vì quay 20° là đường ngắn hơn.
double shortestAngleDiff(double from, double to) {
  var diff = (to - from) % 360;
  if (diff < -180) diff += 360;
  if (diff > 180) diff -= 360;
  return diff;
}

/// Làm mượt tín hiệu la bàn bằng Exponential Moving Average (EMA).
///
/// Cảm biến la bàn (magnetometer) trên điện thoại rất dễ bị nhiễu/giật
/// — nếu vẽ marker thẳng theo giá trị thô, marker sẽ rung liên tục dù
/// tay cầm máy khá yên. EMA giúp mượt hóa mà vẫn phản hồi đủ nhanh khi
/// người dùng thật sự xoay người.
///
/// [alpha] càng nhỏ càng mượt nhưng phản hồi chậm hơn; 0.15 là điểm
/// cân bằng hợp lý cho use-case này (có thể tinh chỉnh sau khi test
/// trên thiết bị thật).
class HeadingSmoother {
  final double alpha;
  double? _smoothed;

  HeadingSmoother({this.alpha = 0.15});

  double add(double rawHeading) {
    if (_smoothed == null) {
      _smoothed = rawHeading;
      return rawHeading;
    }
    final diff = shortestAngleDiff(_smoothed!, rawHeading);
    var next = _smoothed! + alpha * diff;
    next = next % 360;
    if (next < 0) next += 360;
    _smoothed = next;
    return next;
  }
}

/// Chuyển góc la bàn (độ) sang chữ cái phương hướng — chỉ mang tính
/// hiển thị (vd "127° SE"), không ảnh hưởng logic đặt marker.
String headingToCardinal(double heading) {
  const directions = [
    'B', 'BĐB', 'ĐB', 'ĐĐB', // North, NNE, NE, ENE
    'Đ', 'ĐĐN', 'ĐN', 'NĐN', // East, ESE, SE, SSE
    'N', 'NTN', 'TN', 'TTN', // South, SSW, SW, WSW
    'T', 'TTB', 'TB', 'BTB', // West, WNW, NW, NNW
  ];
  final index = ((heading % 360) / 22.5).round() % 16;
  return directions[index];
}
