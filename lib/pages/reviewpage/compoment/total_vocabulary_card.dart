import 'package:flutter/material.dart';

class TotalVocabularyCard extends StatelessWidget {
  final Color color;
  final EdgeInsets tabContainerMargin;
  final EdgeInsets tabContainerPadding;
  final String level;
  final VoidCallback onTap;
  final Map<String, dynamic> vocabularyData;

  const TotalVocabularyCard({
    super.key,
    required this.color,
    required this.tabContainerMargin,
    required this.tabContainerPadding,
    required this.level,
    required this.onTap,
    required this.vocabularyData,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: tabContainerMargin,
        padding: tabContainerPadding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getVocabularyByMemoryLevel(level, vocabularyData)
                  .length
                  .toString(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600),
            ),
            const Divider(color: Colors.white, thickness: 1),
            Text(level, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> getVocabularyByMemoryLevel(
    String targetMemoryLevel, Map<String, dynamic> vocabularyData) {
  try {
    // Khởi tạo map kết quả
    Map<String, dynamic> filteredVocabs = {};

    // Duyệt qua tất cả các entries trong vocabularyData
    vocabularyData.forEach((vocab, data) {
      // Kiểm tra nếu data là Map và có chứa trường memoryLevel
      if (data is Map && data.containsKey('memoryLevel')) {
        // Nếu memoryLevel khớp với target, thêm vào kết quả
        if (data['memoryLevel'] == targetMemoryLevel) {
          filteredVocabs[vocab] = data;
        }
      }
    });

    return filteredVocabs;
  } catch (e) {
    throw Exception("Failed to filter vocabulary by memory level: $e");
  }
}
