import '../../../core/network/api_client.dart';
import '../models/customer_models.dart';

class CustomersRepository {
  CustomersRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ManagedCustomerWorkspace> fetchCustomerWorkspace(String customerId) async {
    final json = await _apiClient.getJson('/api/client/customers/$customerId');
    return ManagedCustomerWorkspace.fromJson(json);
  }

  Future<ManagedCustomerWorkspace> createCustomerFromLead(String leadId) async {
    final json = await _apiClient.postJson('/api/client/customers', {
      'leadId': leadId,
    });
    return ManagedCustomerWorkspace.fromJson(json);
  }

  Future<ManagedCustomerRecord> updateCustomer(String customerId, Map<String, dynamic> payload) async {
    final json = await _apiClient.patchJson('/api/client/customers/$customerId', payload);
    return ManagedCustomerRecord.fromJson(json['customer'] as Map<String, dynamic>? ?? const {});
  }
}