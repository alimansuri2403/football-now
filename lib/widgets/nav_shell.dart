import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class NavShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const NavShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onTap(BuildContext context, int index) {
    if (index == 5) {
      // "More" tapped -> Open drawer
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= AppConstants.tabletBreakpoint;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: !isDesktop ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (isDesktop) ...[
            _buildSidebar(context),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: widget.navigationShell,
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: widget.navigationShell.currentIndex >= 5 ? 5 : widget.navigationShell.currentIndex,
              onTap: (index) => _onTap(context, index),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.sports_soccer),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.live_tv),
                  label: 'Live',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.table_chart),
                  label: 'Standings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: 'Teams',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.leaderboard),
                  label: 'Stats',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.menu),
                  label: 'More',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 260,
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                'FIFA 2026',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Tournament
                  _buildSectionHeader(theme, 'TOURNAMENT'),
                  _SidebarItem(
                    icon: Icons.sports_soccer,
                    label: 'Home',
                    isSelected: widget.navigationShell.currentIndex == 0,
                    onTap: () => widget.navigationShell.goBranch(0),
                  ),
                  _SidebarItem(
                    icon: Icons.live_tv,
                    label: 'Live Matches',
                    isSelected: widget.navigationShell.currentIndex == 1,
                    onTap: () => widget.navigationShell.goBranch(1),
                  ),
                  _SidebarItem(
                    icon: Icons.table_chart,
                    label: 'Standings',
                    isSelected: widget.navigationShell.currentIndex == 2,
                    onTap: () => widget.navigationShell.goBranch(2),
                  ),
                  _SidebarItem(
                    icon: Icons.groups,
                    label: 'Teams',
                    isSelected: widget.navigationShell.currentIndex == 3,
                    onTap: () => widget.navigationShell.goBranch(3),
                  ),
                  _SidebarItem(
                    icon: Icons.leaderboard,
                    label: 'Player Stats',
                    isSelected: widget.navigationShell.currentIndex == 4,
                    onTap: () => widget.navigationShell.goBranch(4),
                  ),
                  _SidebarItem(
                    icon: Icons.account_tree_outlined,
                    label: 'Knockout Bracket',
                    isSelected: widget.navigationShell.currentIndex == 5,
                    onTap: () => widget.navigationShell.goBranch(5),
                  ),
                  
                  const SizedBox(height: 16),

                  // Section 2: Fan Zone
                  _buildSectionHeader(theme, 'FAN ZONE'),
                  _SidebarItem(
                    icon: Icons.auto_awesome,
                    label: 'AI Predictions',
                    isSelected: false,
                    onTap: () => context.push('/prediction'),
                  ),
                  _SidebarItem(
                    icon: Icons.alt_route,
                    label: 'Bracket Simulator',
                    isSelected: false,
                    onTap: () => context.push('/bracket-simulator'),
                  ),
                  _SidebarItem(
                    icon: Icons.quiz,
                    label: 'Fan Challenges',
                    isSelected: false,
                    onTap: () => context.push('/challenges'),
                  ),
                  _SidebarItem(
                    icon: Icons.star_border,
                    label: 'Fantasy Squad',
                    isSelected: false,
                    onTap: () => context.push('/fantasy'),
                  ),
                  _SidebarItem(
                    icon: Icons.stadium_outlined,
                    label: 'Stadium Explorer',
                    isSelected: false,
                    onTap: () => context.push('/stadiums'),
                  ),
                  _SidebarItem(
                    icon: Icons.compare_arrows,
                    label: 'Player Comparison',
                    isSelected: false,
                    onTap: () => context.push('/comparison'),
                  ),
                  _SidebarItem(
                    icon: Icons.trending_up,
                    label: 'Power Rankings',
                    isSelected: false,
                    onTap: () => context.push('/power-rankings'),
                  ),
                  _SidebarItem(
                    icon: Icons.map_outlined,
                    label: 'World Cup Journey',
                    isSelected: false,
                    onTap: () => context.push('/journey'),
                  ),
                  _SidebarItem(
                    icon: Icons.color_lens_outlined,
                    label: 'Team Support Mode',
                    isSelected: false,
                    onTap: () => context.push('/support'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest User',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Fan Profile',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.black, size: 36),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FIFA 2026',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 22),
                        ),
                        Text(
                          'Fan Zone & Predictors',
                          style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Options List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerHeaderLabel(theme, 'TOURNAMENT OVERVIEWS'),
                  _buildDrawerItem(
                    icon: Icons.account_tree_outlined,
                    label: 'Knockout Bracket',
                    onTap: () {
                      Navigator.pop(context);
                      widget.navigationShell.goBranch(5);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.map_outlined,
                    label: 'World Cup Journey',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/journey');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.stadium_outlined,
                    label: 'Stadium Explorer',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/stadiums');
                    },
                  ),
                  
                  const Divider(),
                  _buildDrawerHeaderLabel(theme, 'FAN ZONE EXTRAS'),
                  _buildDrawerItem(
                    icon: Icons.auto_awesome,
                    label: 'AI Predictions',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/prediction');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.alt_route,
                    label: 'Bracket Simulator',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/bracket-simulator');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.quiz,
                    label: 'Fan Challenges',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/challenges');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.star_border,
                    label: 'Fantasy Squad',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/fantasy');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.compare_arrows,
                    label: 'Player Comparison',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/comparison');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    label: 'Power Rankings',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/power-rankings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.color_lens_outlined,
                    label: 'Team Support Mode',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/support');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeaderLabel(ThemeData theme, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: onTap,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? theme.colorScheme.primary.withOpacity(0.15) : theme.colorScheme.primary.withOpacity(0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
