import 'package:flutter/material.dart';

void main() {
  runApp(const TDashApp());
}

class TDashApp extends StatelessWidget {
  const TDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'T-Dash',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF38D996),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF070A0F),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const _TopBar(),
              const SizedBox(height: 24),
              const Expanded(child: _SpeedPanel()),
              const SizedBox(height: 18),
              const _BatteryPanel(),
              const SizedBox(height: 14),
              const _StatusGrid(),
              const SizedBox(height: 14),
              _ControlBar(
                onPlaceholderTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('控制功能开发中')));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('设置页开发中')));
          },
          icon: const Icon(Icons.menu),
          tooltip: '菜单',
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Model 3',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 2),
              Text(
                'BLE 已连接',
                style: TextStyle(
                  color: Color(0xFF38D996),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x1A38D996),
            border: Border.all(color: const Color(0x6638D996)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '86%',
            style: TextStyle(
              color: Color(0xFF38D996),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  const _SpeedPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final shortestSide = constraints.biggest.shortestSide;
          final diameter = (shortestSide.isFinite ? shortestSide : 330.0).clamp(
            0.0,
            330.0,
          );

          return SizedBox.square(
            dimension: diameter,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x335DA0FF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2238D996),
                    blurRadius: 48,
                    spreadRadius: 4,
                  ),
                ],
                gradient: const RadialGradient(
                  colors: [Color(0xFF0A0E14), Color(0xFF111A24)],
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PillLabel(text: 'GPS'),
                          SizedBox(width: 8),
                          _PillLabel(text: '停车'),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '0',
                        style: TextStyle(
                          fontSize: 112,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'km/h',
                        style: TextStyle(
                          color: Color(0xFF9AA5B3),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF283546)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF9AA5B3),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BatteryPanel extends StatelessWidget {
  const _BatteryPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.86,
              minHeight: 12,
              backgroundColor: Color(0xFF26313F),
              color: Color(0xFF38D996),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '86%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(' 电量'),
                ],
              ),
              Row(
                children: [
                  Text(
                    '412',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(' km 续航'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatusTile(icon: Icons.air, label: '空调', value: '待机 22°C'),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatusTile(
            icon: Icons.tire_repair,
            label: '胎压',
            value: '2.8 / 2.8',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatusTile(
            icon: Icons.electric_bolt,
            label: '充电',
            value: '未连接',
          ),
        ),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF5DA0FF)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF647080), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.onPlaceholderTap});

  final VoidCallback onPlaceholderTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ControlButton(
            icon: Icons.directions_car,
            label: '模拟行驶',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlButton(
            icon: Icons.lock_open,
            label: '解锁',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlButton(
            icon: Icons.air,
            label: '空调',
            onTap: onPlaceholderTap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ControlButton(
            icon: Icons.flash_on,
            label: '闪灯',
            onTap: onPlaceholderTap,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xCC101722),
        border: Border.all(color: const Color(0xFF283546)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}
