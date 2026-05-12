
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  final DateTime? selectedDate;
  final Color accentColor;
  final VoidCallback onTap;

  // Fungsi untuk memformat DateTime 
  static String formatTanggal(DateTime date) {
    const hariList  = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const bulanList = ['','Januari','Februari','Maret','April','Mei','Juni',
                       'Juli','Agustus','September','Oktober','November','Desember'];
    return '${hariList[date.weekday - 1]}, ${date.day} ${bulanList[date.month]} ${date.year}';
  }

  const DatePickerField({
    super.key,
    required this.selectedDate,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedDate != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? accentColor.withOpacity(0.05)
              : Colors.grey.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: isSelected ? accentColor : Colors.grey, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Jatuh Tempo',
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? accentColor : Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected
                        ? formatTanggal(selectedDate!)
                        : 'Ketuk untuk memilih tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color:
                          isSelected ? const Color(0xFF212121) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: isSelected ? accentColor : Colors.grey),
          ],
        ),
      ),
    );
  }
}