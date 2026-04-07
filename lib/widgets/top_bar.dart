import 'package:flutter/material.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.onMenuTap,
    this.searchController,
    this.onSearchChanged,
    this.searchHintText = 'Search items',
  });

  final String title;
  final VoidCallback onMenuTap;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHintText;

  bool get _showsSearch => searchController != null && onSearchChanged != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      color: const Color(0xFF4CAF50),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.menu, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 18),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_showsSearch) ...[
            const SizedBox(width: 18),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: searchHintText,
                      hintStyle: const TextStyle(color: Colors.black45),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black54,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ] else
            const Spacer(),
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
          if (!_showsSearch) ...[
            const SizedBox(width: 20),
            const Icon(Icons.search, color: Colors.white, size: 28),
          ],
        ],
      ),
    );
  }
}
