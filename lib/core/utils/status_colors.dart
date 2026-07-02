import 'package:flutter/material.dart';

/// Mirrors status_badge()'s class map (app/helpers.php) and the dark-theme
/// badge colors in resources/views/layouts/app.blade.php (.bs/.bi/.bw/...)
/// so status chips read the same on mobile as on the web app.
const Map<String, Color> _badgeColors = {
  'bs': Color(0xFF34D399),
  'bw': Color(0xFFFBBF24),
  'bd': Color(0xFFF87171),
  'bi': Color(0xFF60A5FA),
  'bp': Color(0xFFA78BFA),
  'bx': Color(0xFF94A3B8),
  'bo': Color(0xFFFB923C),
  'bt': Color(0xFF2DD4BF),
};

const Map<String, String> _statusClass = {
  'received': 'bi',
  'diagnosing': 'bp',
  'waiting_parts': 'bw',
  'repairing': 'bo',
  'ready': 'bt',
  'delivered': 'bs',
  'draft': 'bx',
  'warranty': 'bp',
  'cancelled': 'bx',
};

Color repairStatusColor(String status) => _badgeColors[_statusClass[status] ?? 'bx']!;

const Map<String, Color> _priorityColors = {
  'low': Color(0xFF94A3B8),
  'normal': Color(0xFF94A3B8),
  'medium': Color(0xFF60A5FA),
  'high': Color(0xFFFBBF24),
  'urgent': Color(0xFFF87171),
};

Color repairPriorityColor(String? priority) => _priorityColors[priority ?? 'normal'] ?? _priorityColors['normal']!;

const Map<String, Color> _orderStatusColors = {
  'pending': Color(0xFF60A5FA),
  'processing': Color(0xFFFBBF24),
  'completed': Color(0xFF34D399),
  'failed': Color(0xFFF87171),
  'cancelled': Color(0xFF94A3B8),
};

Color orderStatusColor(String status) => _orderStatusColors[status] ?? _orderStatusColors['pending']!;

const Map<String, Color> _poStatusColors = {
  'draft': Color(0xFF94A3B8),
  'ordered': Color(0xFF60A5FA),
  'received': Color(0xFF34D399),
  'cancelled': Color(0xFFF87171),
};

Color poStatusColor(String status) => _poStatusColors[status] ?? _poStatusColors['draft']!;
