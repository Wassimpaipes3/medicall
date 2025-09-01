import 'package:flutter/material.dart';

class MedicalServicesCarousel extends StatelessWidget {
  final List<MedicalService> services = [
    MedicalService(
      icon: Icons.location_on,
      title: 'Map Tracking',
      color: Colors.red,
      route: '/map-demo',
    ),
    MedicalService(
      icon: Icons.elderly,
      title: 'Elderly Care',
      color: Colors.teal,
    ),
    MedicalService(
      icon: Icons.medical_services,
      title: 'Wound Care',
      color: Colors.blue,
    ),
    MedicalService(
      icon: Icons.medication_liquid,
      title: 'IV Therapy',
      color: Colors.green,
    ),
    MedicalService(
      icon: Icons.bed,
      title: 'Bedridden Care',
      color: Colors.cyan,
    ),
    MedicalService(
      icon: Icons.medical_information,
      title: 'Post-Op Care',
      color: Colors.lightBlue,
    ),
    MedicalService(
      icon: Icons.monitor_heart,
      title: 'Cardiac Care',
      color: Colors.teal,
    ),
  ];

  MedicalServicesCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Medical Services',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        SizedBox(
          height: 110,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            itemBuilder: (context, index) {
              return _buildServiceCard(services[index], context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard(MedicalService service, BuildContext context) {
    return Container(
      width: 85,
      margin: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle navigation if route is provided
            if (service.route != null) {
              Navigator.of(context).pushNamed(service.route!);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with pill-shaped background
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: service.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(service.icon, size: 20, color: service.color),
                ),
                const SizedBox(height: 4),
                // Title text with subtle styling
                Text(
                  service.title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MedicalService {
  final IconData icon;
  final String title;
  final Color color;
  final String? route;

  MedicalService({
    required this.icon,
    required this.title,
    required this.color,
    this.route,
  });
}
