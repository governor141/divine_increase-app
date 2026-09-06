/// Represents a business card shown on the Home screen's "Featured
/// Businesses" strip. Currently populated with placeholder data in
/// home_screen.dart — Phase 2 will load these from your Firestore
/// `featuredBusinesses` collection (or whatever it's named on your
/// backend) so anything you add as admin shows up automatically.
class Business {
  final String name;
  final String category;
  final String location;
  final bool sponsored;

  const Business({
    required this.name,
    required this.category,
    required this.location,
    this.sponsored = false,
  });
}
