import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/location_service.dart';

class AddressField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Function(PlaceLocation location) onLocationSelected;
  final String? validator;

  const AddressField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onLocationSelected,
    this.validator,
  });

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  final _controller = TextEditingController();
  final _locationService = LocationService();
  final _focusNode = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      if (value.length < 3) {
        setState(() => _suggestions = []);
        return;
      }
      final results = await _locationService.getPlaceSuggestions(value);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _showSuggestions = results.isNotEmpty;
        });
      }
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _controller.text = suggestion.description;
    setState(() => _showSuggestions = false);

    final location =
        await _locationService.getPlaceDetails(suggestion.placeId);
    if (location != null) {
      widget.onLocationSelected(location);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon),
          ),
          validator: widget.validator != null
              ? (v) =>
                  v == null || v.trim().isEmpty ? widget.validator : null
              : null,
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.location_on_outlined,
                      size: 20, color: AppColors.primary),
                  title: Text(
                    s.description,
                    style: const TextStyle(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          ),
      ],
    );
  }
}
