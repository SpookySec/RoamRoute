import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme/duo_theme.dart';
import '../services/sound_service.dart';
import 'duo_card.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const TripCard({
    Key? key,
    required this.trip,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: () {
          DuoSoundService.playClick();
          onTap();
        },
        child: DuoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DuoColors.duoBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.place, color: DuoColors.duoBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.destination.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: DuoColors.duoTextMain,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${trip.startDate} — ${trip.endDate}',
                          style: const TextStyle(
                            color: DuoColors.duoGray,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, color: DuoColors.duoGray),
                    onPressed: onShare,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: DuoColors.duoRed),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (trip.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  trip.notes,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: DuoColors.duoGray,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
