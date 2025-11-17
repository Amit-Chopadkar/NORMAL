import 'package:flutter/material.dart';
import '../models/place_model.dart';

class FilterChipWidget extends StatelessWidget {
  final PlaceCategory category;
  final Function(String) onSelected;

  const FilterChipWidget({
    super.key,
    required this.category,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(category.name),
      selected: category.isSelected,
      onSelected: (selected) => onSelected(category.id),
      selectedColor: Colors.blue[800],
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: category.isSelected ? Colors.white : Colors.grey[600],
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: category.isSelected ? Colors.blue[800]! : Colors.grey[300]!,
        ),
      ),
    );
  }
}