import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/presentation/veloprime_ui.dart';
import '../../bootstrap/models/bootstrap_payload.dart';

final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'pl_PL',
  symbol: 'PLN',
  decimalDigits: 0,
);

final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');

String _formatCurrency(num? value) {
  if (value == null) {
    return 'Do ustalenia';
  }

  return _currencyFormat.format(value);
}

String _formatDateLabel(String? value) {
  if (value == null || value.isEmpty) {
    return 'Bez terminu';
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return 'Bez terminu';
  }

  return _dateFormat.format(parsed);
}

String _roleLabel(String role) {
  switch (role) {
    case 'ADMIN':
      return 'Administrator';
    case 'DIRECTOR':
      return 'Dyrektor';
    case 'MANAGER':
      return 'Manager';
    default:
      return 'Handlowiec';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'APPROVED':
      return 'Zaakceptowane';
    case 'SENT':
      return 'Wysłane';
    case 'REJECTED':
      return 'Odrzucone';
    case 'EXPIRED':
      return 'Wygasłe';
    default:
      return 'Szkice';
  }
}

Color _statusTone(String status) {
  switch (status) {
    case 'APPROVED':
      return const Color(0xFF3F7D64);
    case 'SENT':
      return VeloPrimePalette.sea;
    case 'REJECTED':
      return const Color(0xFFA35A4A);
    case 'EXPIRED':
      return const Color(0xFF8A857A);
    default:
      return VeloPrimePalette.bronzeDeep;
  }
}

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({
    super.key,
    required this.session,
    required this.bootstrap,
    required this.onOpenLeads,
    required this.onOpenOffers,
    required this.onOpenCustomers,
    required this.onOpenVehicles,
  });

  final SessionInfo session;
  final BootstrapPayload bootstrap;
  final VoidCallback onOpenLeads;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenCustomers;
  final VoidCallback onOpenVehicles;

  @override
  Widget build(BuildContext context) {
    final uniqueModels = bootstrap.pricingOptions
        .map((option) => '${option.brand}::${option.model}'.trim())
        .where((value) => value.isNotEmpty && value != '::')
        .toSet()
        .length;
    final draftOffers = bootstrap.offers.where((offer) => offer.status == 'DRAFT').length;
    final sentOffers = bootstrap.offers.where((offer) => offer.status == 'SENT').length;
    final approvedOffers = bootstrap.offers.where((offer) => offer.status == 'APPROVED').length;
    final sortedOffers = [...bootstrap.offers]
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    final featuredOffer = sortedOffers.isEmpty ? null : sortedOffers.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VeloPrimeShell(
        decorateBackground: false,
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHero(
                session: session,
                leadCount: bootstrap.leadOptions.length,
                offerCount: bootstrap.offers.length,
                pricingCount: bootstrap.pricingOptions.length,
                uniqueModels: uniqueModels,
                featuredOffer: featuredOffer,
                onOpenLeads: onOpenLeads,
                onOpenOffers: onOpenOffers,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1120;
                  final metricCards = [
                    VeloPrimeMetricCard(
                      label: 'Leady aktywne',
                      value: '${bootstrap.leadOptions.length}',
                      accentColor: VeloPrimePalette.sea,
                    ),
                    VeloPrimeMetricCard(
                      label: 'Oferty PDF',
                      value: '${bootstrap.offers.length}',
                      accentColor: VeloPrimePalette.bronzeDeep,
                    ),
                    VeloPrimeMetricCard(
                      label: 'Modele w katalogu',
                      value: '$uniqueModels',
                      accentColor: VeloPrimePalette.olive,
                    ),
                    VeloPrimeMetricCard(
                      label: 'Szkice robocze',
                      value: '$draftOffers',
                      accentColor: const Color(0xFF8F6B18),
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      children: metricCards
                          .map(
                            (card) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: card,
                              ),
                            ),
                          )
                          .toList()
                        ..removeLast()
                        ..add(Expanded(child: metricCards.last)),
                    );
                  }

                  return Wrap(spacing: 16, runSpacing: 16, children: metricCards);
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1080;
                  final navigationCard = VeloPrimeWorkspacePanel(
                    tint: VeloPrimePalette.bronzeDeep,
                    radius: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VeloPrimeSectionEyebrow(label: 'Nawigacja robocza'),
                        const SizedBox(height: 10),
                        const Text(
                          'Przejdź od przeglądu do działania.',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.08),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Dashboard ma prowadzić wzrok i skracać drogę do kolejnej czynności. Dlatego najważniejsze obszary pracy są tu pokazane jako klarowne, lekkie moduły.',
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                        ),
                        const SizedBox(height: 22),
                        _DashboardModuleTile(
                          title: 'Dashboard',
                          description: 'Widok premium do codziennego startu, przeglądu pipeline i kluczowych sygnałów sprzedażowych.',
                          accentColor: VeloPrimePalette.bronzeDeep,
                          icon: Icons.dashboard_outlined,
                        ),
                        const SizedBox(height: 12),
                        _DashboardModuleTile(
                          title: 'Leady',
                          description: 'Kanban handlowy, obsługa kontaktów i przejście z leada do oferty w jednym strumieniu pracy.',
                          accentColor: VeloPrimePalette.sea,
                          icon: Icons.view_kanban_outlined,
                          onTap: onOpenLeads,
                        ),
                        const SizedBox(height: 12),
                        _DashboardModuleTile(
                          title: 'Klienci',
                          description: 'Docelowe centrum relacji i historii obsługi po przejściu z leada do właściwej współpracy.',
                          accentColor: VeloPrimePalette.olive,
                          icon: Icons.groups_2_outlined,
                          onTap: onOpenCustomers,
                        ),
                        const SizedBox(height: 12),
                        _DashboardModuleTile(
                          title: 'Samochody',
                          description: 'Moduł oferty modelowej i floty, utrzymany jako osobna warstwa produktowa CRM.',
                          accentColor: VeloPrimePalette.rose,
                          icon: Icons.directions_car_outlined,
                          onTap: onOpenVehicles,
                        ),
                        const SizedBox(height: 12),
                        _DashboardModuleTile(
                          title: 'Oferty PDF',
                          description: 'Generator ofert z kalkulacją, podglądem dokumentu i finalizacją PDF w jednym workspace.',
                          accentColor: VeloPrimePalette.bronzeDeep,
                          icon: Icons.description_outlined,
                          onTap: onOpenOffers,
                        ),
                      ],
                    ),
                  );

                  final summaryCard = VeloPrimeWorkspacePanel(
                    tint: VeloPrimePalette.sea,
                    radius: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VeloPrimeSectionEyebrow(label: 'Pulse'),
                        const SizedBox(height: 10),
                        const Text(
                          'Sygnały sprzedażowe na dziś.',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, height: 1.08),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ten panel ma dawać natychmiastowy ogląd sytuacji: co jest gotowe do ruchu, gdzie jest aktywność i jaka część pracy wymaga kolejnego kroku.',
                          style: TextStyle(color: VeloPrimePalette.muted, height: 1.55),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFFFFF), Color(0xFFF8F5F0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: VeloPrimePalette.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stan ofert',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _StatusChip(label: _statusLabel('DRAFT'), value: '$draftOffers', tone: _statusTone('DRAFT')),
                                  _StatusChip(label: _statusLabel('SENT'), value: '$sentOffers', tone: _statusTone('SENT')),
                                  _StatusChip(label: _statusLabel('APPROVED'), value: '$approvedOffers', tone: _statusTone('APPROVED')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SummaryLine(
                          label: 'Aktywna sesja',
                          value: '${session.fullName} • ${_roleLabel(session.role)}',
                        ),
                        const SizedBox(height: 10),
                        _SummaryLine(
                          label: 'Leady do pracy',
                          value: '${bootstrap.leadOptions.length} kontaktów',
                        ),
                        const SizedBox(height: 10),
                        _SummaryLine(
                          label: 'Katalog modeli',
                          value: '$uniqueModels linii modelowych',
                        ),
                        if (featuredOffer != null) ...[
                          const SizedBox(height: 18),
                          _FeaturedOfferCard(offer: featuredOffer),
                        ],
                      ],
                    ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: navigationCard),
                        const SizedBox(width: 20),
                        Expanded(flex: 2, child: summaryCard),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      navigationCard,
                      const SizedBox(height: 20),
                      summaryCard,
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.session,
    required this.leadCount,
    required this.offerCount,
    required this.pricingCount,
    required this.uniqueModels,
    required this.featuredOffer,
    required this.onOpenLeads,
    required this.onOpenOffers,
  });

  final SessionInfo session;
  final int leadCount;
  final int offerCount;
  final int pricingCount;
  final int uniqueModels;
  final ManagedOfferSummary? featuredOffer;
  final VoidCallback onOpenLeads;
  final VoidCallback onOpenOffers;

  @override
  Widget build(BuildContext context) {
    return VeloPrimeWorkspacePanel(
      tint: VeloPrimePalette.bronzeDeep,
      radius: 30,
      padding: const EdgeInsets.all(28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1040;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VeloPrimeSectionEyebrow(label: 'Dashboard'),
              const SizedBox(height: 12),
              const Text(
                'Pulpit sprzedażowy zaprojektowany jak produkt premium, nie jak panel techniczny.',
                style: TextStyle(
                  color: VeloPrimePalette.ink,
                  fontSize: 40,
                  height: 1.04,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Witaj ${session.fullName}. Z tego miejsca przechodzisz od szybkiego obrazu pipeline do konkretnej akcji: leada, oferty PDF albo pracy na katalogu modeli. Dashboard ma porządkować uwagę i skracać drogę do działania.',
                style: const TextStyle(
                  color: VeloPrimePalette.muted,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: onOpenLeads,
                    icon: const Icon(Icons.view_kanban_outlined),
                    label: const Text('Przejdź do leadów'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenOffers,
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Otwórz oferty PDF'),
                  ),
                ],
              ),
            ],
          );

          final sidePanel = _HeroInsightPanel(
            session: session,
            leadCount: leadCount,
            offerCount: offerCount,
            pricingCount: pricingCount,
            uniqueModels: uniqueModels,
            featuredOffer: featuredOffer,
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: copy),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: sidePanel),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 20), sidePanel],
          );
        },
      ),
    );
  }
}

class _HeroInsightPanel extends StatelessWidget {
  const _HeroInsightPanel({
    required this.session,
    required this.leadCount,
    required this.offerCount,
    required this.pricingCount,
    required this.uniqueModels,
    required this.featuredOffer,
  });

  final SessionInfo session;
  final int leadCount;
  final int offerCount;
  final int pricingCount;
  final int uniqueModels;
  final ManagedOfferSummary? featuredOffer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F5EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: VeloPrimePalette.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10111111),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF4E4BD), Color(0xFFE0C178)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF7E5C15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dzisiaj w CRM',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_roleLabel(session.role)} • ${session.email}',
                      style: const TextStyle(color: VeloPrimePalette.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Leady', value: '$leadCount')),
              const SizedBox(width: 12),
              Expanded(child: _HeroStat(label: 'Oferty', value: '$offerCount')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _HeroStat(label: 'Pozycje', value: '$pricingCount')),
              const SizedBox(width: 12),
              Expanded(child: _HeroStat(label: 'Modele', value: '$uniqueModels')),
            ],
          ),
          if (featuredOffer != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: VeloPrimePalette.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ostatnio aktywna oferta',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: VeloPrimePalette.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featuredOffer!.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${featuredOffer!.customerName} • ${featuredOffer!.modelName ?? 'Model do uzupełnienia'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: VeloPrimePalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: VeloPrimePalette.ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardModuleTile extends StatelessWidget {
  const _DashboardModuleTile({
    required this.title,
    required this.description,
    required this.accentColor,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String description;
  final Color accentColor;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color.lerp(accentColor, Colors.white, 0.95) ?? Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: VeloPrimePalette.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D111111),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(accentColor, Colors.white, 0.82) ?? Colors.white,
                      Color.lerp(accentColor, Colors.white, 0.94) ?? Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded, color: VeloPrimePalette.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Color.lerp(tone, Colors.white, 0.9) ?? Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Color.lerp(tone, Colors.white, 0.76) ?? tone),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: tone, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: VeloPrimePalette.ink, fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FeaturedOfferCard extends StatelessWidget {
  const _FeaturedOfferCard({required this.offer});

  final ManagedOfferSummary offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8F6F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VeloPrimePalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color.lerp(_statusTone(offer.status), Colors.white, 0.88) ?? Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  _statusLabel(offer.status),
                  style: TextStyle(
                    color: _statusTone(offer.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                offer.number,
                style: const TextStyle(
                  color: VeloPrimePalette.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            offer.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            '${offer.customerName} • ${offer.modelName ?? 'Model do uzupełnienia'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: VeloPrimePalette.muted, height: 1.45),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfo(label: 'Wartość', value: _formatCurrency(offer.totalGross)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniInfo(label: 'Ważna do', value: _formatDateLabel(offer.validUntil)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: VeloPrimePalette.muted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: VeloPrimePalette.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: VeloPrimePalette.muted),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: VeloPrimePalette.ink),
        ),
      ],
    );
  }
}