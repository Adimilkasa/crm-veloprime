import 'package:flutter_test/flutter_test.dart';
import 'package:veloprime_hybrid_app/core/network/api_client.dart';
import 'package:veloprime_hybrid_app/features/auth/data/auth_repository.dart';
import 'package:veloprime_hybrid_app/features/bootstrap/data/bootstrap_repository.dart';
import 'package:veloprime_hybrid_app/features/leads/data/leads_repository.dart';
import 'package:veloprime_hybrid_app/features/offers/data/offers_repository.dart';

const runApiSmoke = bool.fromEnvironment('RUN_API_SMOKE');

void main() {
  group('Flutter API smoke', () {
    test(
      'login, bootstrap, create offer and fetch PDF snapshot',
      () async {
        final apiClient = ApiClient();
        final authRepository = AuthRepository(apiClient);
        final bootstrapRepository = BootstrapRepository(apiClient);
        final offersRepository = OffersRepository(apiClient);

        await authRepository.login(
          email: 'admin@veloprime.pl',
          password: 'Admin123!',
        );

        final bootstrap = await bootstrapRepository.loadBootstrap();

        expect(bootstrap.session.email, 'admin@veloprime.pl');
        expect(bootstrap.session.role, 'ADMIN');

        final createdOffer = await offersRepository.createOffer({
          'title': 'FLUTTER_SMOKE_OFFER',
          'customerType': 'PRIVATE',
          'customerName': 'Flutter Smoke Customer',
          'customerEmail': 'flutter.smoke.customer@veloprime.pl',
          'customerPhone': '+48500111222',
          'customerRegion': 'Warszawa',
          'financingVariant': 'kredyt',
          'financingTermMonths': '36',
          'financingInputValue': '20000',
          'financingBuyoutPercent': '20',
          'validUntil': DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T').first,
          'notes': 'Flutter repository smoke test',
        });

        expect(createdOffer.id, isNotEmpty);
        expect(createdOffer.title, 'FLUTTER_SMOKE_OFFER');

        final detail = await offersRepository.fetchOfferDetail(createdOffer.id);

        expect(detail.id, createdOffer.id);
        expect(detail.customerName, isNotEmpty);

        final version = await offersRepository.createPdfVersion(offerId: createdOffer.id);

        expect(version.id, isNotEmpty);
        expect(version.versionNumber, greaterThanOrEqualTo(1));

        final document = await offersRepository.fetchDocumentSnapshot(
          offerId: createdOffer.id,
          versionId: version.id,
        );

        expect(document.offerId, createdOffer.id);
        expect(document.version?.id, version.id);
        expect(document.payload.customer.offerNumber, isNotEmpty);
      },
      skip: !runApiSmoke,
    );

    test(
      'login, create lead, move stage and add detail entry',
      () async {
        final apiClient = ApiClient();
        final authRepository = AuthRepository(apiClient);
        final leadsRepository = LeadsRepository(apiClient);
        final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;

        await authRepository.login(
          email: 'admin@veloprime.pl',
          password: 'Admin123!',
        );

        final overview = await leadsRepository.fetchLeads();
        final openStages = overview.stages.where((stage) => stage.kind == 'OPEN').toList();

        expect(openStages, isNotEmpty);

        final firstStage = openStages.first;
        final secondStage = openStages.length > 1 ? openStages[1] : openStages.first;

        final createdLead = await leadsRepository.createLead({
          'source': 'Flutter Smoke Test',
          'fullName': 'Flutter Smoke Lead $uniqueSuffix',
          'email': 'flutter.smoke.lead.$uniqueSuffix@veloprime.pl',
          'phone': '+48500444555',
          'interestedModel': 'BYD Seal',
          'region': 'Warszawa',
          'message': 'Lead created by Flutter API smoke test',
          'stageId': firstStage.id,
          'salespersonId': '',
        });

        expect(createdLead.lead.id, isNotEmpty);
        expect(createdLead.lead.fullName, contains('Flutter Smoke Lead'));
        expect(createdLead.lead.stageId, firstStage.id);

        final movedLead = await leadsRepository.moveLeadToStage(
          leadId: createdLead.lead.id,
          stageId: secondStage.id,
        );

        expect(movedLead.lead.stageId, secondStage.id);

        final detailedLead = await leadsRepository.addDetailEntry(
          leadId: createdLead.lead.id,
          kind: 'INFO',
          label: 'Smoke check',
          value: 'Lead detail created from Flutter API smoke test',
        );

        expect(detailedLead.lead.details, isNotEmpty);
        expect(
          detailedLead.lead.details.any((entry) => entry.value.contains('Flutter API smoke test')),
          isTrue,
        );
      },
      skip: !runApiSmoke,
    );
  });
}