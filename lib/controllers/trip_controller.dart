import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/user_model.dart';

/// Main Controller for Trip Management (MVC Pattern)
/// Handles all business logic for searching, booking, and admin operations
class TripController extends ChangeNotifier {
  
  // ==================== STATE ====================
  
  /// Loading state for async operations
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  /// All available trips (from Firebase or Mock)
  List<Trip> _allTrips = [];
  List<Trip> get allTrips => _allTrips;
  
  /// Search results after filtering
  List<Trip> _searchResults = [];
  List<Trip> get searchResults => _searchResults;
  
  /// Currently selected trip for booking
  Trip? _selectedTrip;
  Trip? get selectedTrip => _selectedTrip;
  
  /// Selected seats for booking
  final List<int> _selectedSeats = [];
  List<int> get selectedSeats => _selectedSeats;
  
  /// Last generated ticket
  Ticket? _currentTicket;
  Ticket? get currentTicket => _currentTicket;
  
  /// Current user (for authentication)
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  
  /// Admin mode toggle
  bool _isAdminMode = false;
  bool get isAdminMode => _isAdminMode;
  
  // Search form inputs
  String? _fromCity;
  String? get fromCity => _fromCity;
  
  String? _toCity;
  String? get toCity => _toCity;
  
  DateTime? _travelDate;
  DateTime? get travelDate => _travelDate;
  
  // ==================== INITIALIZATION ====================
  
  /// Initialize controller with mock data
  TripController() {
    _loadMockData();
  }
  
  void _loadMockData() {
    _allTrips = Trip.getMockTrips();
    notifyListeners();
  }
  
  // ==================== USER ACTIONS (BL-01, BL-02) ====================
  
  /// Update search form fields
  void setFromCity(String? city) {
    _fromCity = city;
    notifyListeners();
  }
  
  void setToCity(String? city) {
    _toCity = city;
    notifyListeners();
  }
  
  void setTravelDate(DateTime? date) {
    _travelDate = date;
    notifyListeners();
  }
  
  /// BL-01: Search for trips by origin, destination, date
  Future<void> searchTrips(BuildContext context) async {
    // Validation
    if (_fromCity == null || _toCity == null) {
      _showError(context, "Please select both origin and destination cities");
      return;
    }
    
    _setLoading(true);
    
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Filter trips
    _searchResults = _allTrips.where((trip) {
      bool matchesRoute = trip.fromCity == _fromCity && trip.toCity == _toCity;
      
      // For Sprint 1 demo, ignore date filter to show data
      // In production: also check trip.departureTime.day == _travelDate.day
      
      return matchesRoute;
    }).toList();
    
    _setLoading(false);
    
    if (_searchResults.isEmpty) {
      _showInfo(context, "No buses found for this route. Try Colombo to Jaffna/Badulla for demo.");
    }
  }
  
  /// BL-12: Get alternative buses when selected bus is full
  List<Trip> getAlternativeBuses(Trip fullTrip) {
    return _allTrips.where((trip) {
      return trip.fromCity == fullTrip.fromCity &&
             trip.toCity == fullTrip.toCity &&
             trip.id != fullTrip.id &&
             !trip.isFull;
    }).take(3).toList();
  }
  
  /// Select a trip for booking (BL-03)
  void selectTrip(Trip trip) {
    _selectedTrip = trip;
    _selectedSeats.clear();
    notifyListeners();
  }
  
  // ==================== SEAT SELECTION ====================
  
  /// Toggle seat selection
  void toggleSeat(int seatNumber) {
    if (_selectedSeats.contains(seatNumber)) {
      _selectedSeats.remove(seatNumber);
    } else {
      _selectedSeats.add(seatNumber);
    }
    notifyListeners();
  }
  
  /// Clear all selected seats
  void clearSeats() {
    _selectedSeats.clear();
    notifyListeners();
  }
  
  /// Check if seat is available
  bool isSeatAvailable(int seatNumber) {
    if (_selectedTrip == null) return false;
    return !_selectedTrip!.bookedSeats.contains(seatNumber);
  }
  
  // ==================== BOOKING & PAYMENT (BL-06, BL-19) ====================
  
  /// Process booking and payment
  Future<bool> confirmBooking(BuildContext context) async {
    if (_selectedTrip == null || _selectedSeats.isEmpty) {
      _showError(context, "Please select at least one seat");
      return false;
    }
    
    _setLoading(true);
    
    // Simulate payment gateway
    await Future.delayed(const Duration(seconds: 2));
    
    // Generate ticket (BL-06)
    _currentTicket = Ticket(
      ticketId: 'BL${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      trip: _selectedTrip!,
      seatNumbers: List.from(_selectedSeats),
      passengerName: _currentUser?.name ?? 'Demo Passenger',
      passengerPhone: _currentUser?.phone ?? '+94771234567',
      bookingTime: DateTime.now(),
      totalAmount: _selectedTrip!.price * _selectedSeats.length,
      paymentStatus: 'PAID',
    );
    
    // Update booked seats (in real app, update Firebase)
    _selectedTrip!.bookedSeats.addAll(_selectedSeats);
    
    _setLoading(false);
    _showSuccess(context, "Booking confirmed! Your ticket is ready.");
    
    return true;
  }
  
  // ==================== ADMIN ACTIONS (ADM-02, ADM-05, ADM-14) ====================
  
  /// Toggle admin mode (ADM-01)
  void toggleAdminMode() {
    _isAdminMode = !_isAdminMode;
    notifyListeners();
  }
  
  /// Set current user
  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    _isAdminMode = user?.isStaff ?? false;
    notifyListeners();
  }
  
  /// ADM-14: Update platform number
  void updatePlatform(String tripId, String platformNumber) {
    final index = _allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _allTrips[index].platformNumber = platformNumber;
      notifyListeners();
      
      // In real app: Update Firebase
      // await FirebaseFirestore.instance
      //   .collection('trips')
      //   .doc(tripId)
      //   .update({'platformNumber': platformNumber});
    }
  }
  
  /// ADM-05: Update trip status (delay/cancel)
  void updateTripStatus(String tripId, TripStatus newStatus, int delayMinutes) {
    final index = _allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      _allTrips[index].status = newStatus;
      _allTrips[index].delayMinutes = delayMinutes;
      notifyListeners();
      
      // In real app: Update Firebase and send notifications
      // await _sendStatusNotifications(tripId, newStatus, delayMinutes);
    }
  }
  
  /// ADM-02: Add new trip (for route management)
  void addTrip(Trip newTrip) {
    _allTrips.add(newTrip);
    notifyListeners();
  }
  
  /// ADM-02: Remove trip
  void removeTrip(String tripId) {
    _allTrips.removeWhere((t) => t.id == tripId);
    notifyListeners();
  }
  
  // ==================== HELPER METHODS ====================
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  /// Reset booking state
  void resetBooking() {
    _selectedTrip = null;
    _selectedSeats.clear();
    _currentTicket = null;
    notifyListeners();
  }
}