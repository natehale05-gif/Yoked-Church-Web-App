/// The primary navigation destinations, kept short and intuitive.
class NavItem {
  final String label;
  final String path;
  const NavItem(this.label, this.path);
}

const List<NavItem> kNavItems = [
  NavItem('Home', '/'),
  NavItem("I'm New", '/visit'),
  NavItem('Messages', '/sermons'),
  NavItem('Events', '/events'),
  NavItem('Ministries', '/ministries'),
  NavItem('About', '/about'),
];
