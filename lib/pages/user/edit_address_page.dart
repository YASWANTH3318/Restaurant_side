import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';

class EditAddressPage extends StatefulWidget {
  final AddressModel? address;

  const EditAddressPage({super.key, this.address});

  @override
  State<EditAddressPage> createState() => _EditAddressPageState();
}

class _EditAddressPageState extends State<EditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _houseNumberController = TextEditingController();
  final _houseNameController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _houseNumberController.text = widget.address!.houseNumber;
      _houseNameController.text = widget.address!.houseName;
      _landmarkController.text = widget.address!.landmark;
      _streetController.text = widget.address!.street;
      _cityController.text = widget.address!.city;
      _stateController.text = widget.address!.state;
      _pincodeController.text = widget.address!.pincode;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _houseNumberController.dispose();
    _houseNameController.dispose();
    _landmarkController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final address = AddressModel(
        id: widget.address?.id ?? '',
        userId: user.uid,
        houseNumber: _houseNumberController.text,
        houseName: _houseNameController.text,
        landmark: _landmarkController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        isDefault: _isDefault,
      );

      bool success;
      if (widget.address != null) {
        success = await AddressService.updateAddress(address);
      } else {
        final addressId = await AddressService.addAddress(address);
        success = addressId != null;
      }

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save address. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _houseNumberController,
                      decoration: const InputDecoration(
                        labelText: 'House/Flat Number *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter house/flat number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _houseNameController,
                      decoration: const InputDecoration(
                        labelText: 'House/Building Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter house/building name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Street/Area *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter street/area';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _landmarkController,
                      decoration: const InputDecoration(
                        labelText: 'Landmark',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'PIN Code *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter PIN code';
                        }
                        if (value.length != 6) {
                          return 'PIN code must be 6 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CheckboxListTile(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() => _isDefault = value ?? false);
                      },
                      title: const Text('Set as default address'),
                      subtitle: const Text(
                        'This address will be used as the default delivery address'
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.address == null ? 'Add Address' : 'Save Changes'
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 