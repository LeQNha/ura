/// Format khoảng cách dạng "120 m" hoặc "1.2 km" — dùng ở Map (preview
/// card khi bấm marker) để user biết Observation cách mình bao xa, mà
/// không cần geospatial query phức tạp — chỉ là phép tính hiển thị đơn
/// giản trên dữ liệu đã có sẵn ở client.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

/// Format thời lượng dạng "1h 23m" hoặc "23m 05s" — dùng ở Expedition
/// (đồng hồ đếm giờ khi đang thám hiểm + Summary sau khi kết thúc).
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  final seconds = duration.inSeconds % 60;

  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}

/// Format thời gian dạng tương đối kiểu "3 giờ trước", "2 ngày trước".
///
/// Đặt ở core/utils vì sẽ dùng lại ở nhiều nơi: Observation Card,
/// Comment, Notification... không riêng gì Observation feature.
String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);

  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
  return '${(diff.inDays / 365).floor()} năm trước';
}
