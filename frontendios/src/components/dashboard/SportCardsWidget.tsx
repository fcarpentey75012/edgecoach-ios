/**
 * Widget des cartes par sport avec stats enrichies
 * Affiche durée + distance + nombre de séances pour chaque discipline
 */

import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { WeeklySummaryData, DisciplineType, dashboardService } from '../../services';

interface SportCardsWidgetProps {
  weeklyData: WeeklySummaryData | null;
  onPressCard: (discipline: DisciplineType) => void;
}

interface SportCardData {
  discipline: DisciplineType;
  name: string;
  icon: string;
  color: string;
  count: number;
  duration: number;
  distance: number;
}

const SportCardsWidget: React.FC<SportCardsWidgetProps> = ({
  weeklyData,
  onPressCard,
}) => {
  // Construire les données des cartes
  const cards: SportCardData[] = [
    {
      discipline: 'cyclisme',
      name: 'Vélo',
      icon: 'bicycle',
      color: colors.sports.cycling,
      count: weeklyData?.byDiscipline.cyclisme.count || 0,
      duration: weeklyData?.byDiscipline.cyclisme.duration || 0,
      distance: weeklyData?.byDiscipline.cyclisme.distance || 0,
    },
    {
      discipline: 'course',
      name: 'Course',
      icon: 'walk',
      color: colors.sports.running,
      count: weeklyData?.byDiscipline.course.count || 0,
      duration: weeklyData?.byDiscipline.course.duration || 0,
      distance: weeklyData?.byDiscipline.course.distance || 0,
    },
    {
      discipline: 'natation',
      name: 'Natation',
      icon: 'water',
      color: colors.sports.swimming,
      count: weeklyData?.byDiscipline.natation.count || 0,
      duration: weeklyData?.byDiscipline.natation.duration || 0,
      distance: weeklyData?.byDiscipline.natation.distance || 0,
    },
  ];

  // Ajouter "Autre" si des séances existent
  if (weeklyData?.byDiscipline.autre && weeklyData.byDiscipline.autre.count > 0) {
    cards.push({
      discipline: 'autre',
      name: 'Autre',
      icon: 'fitness',
      color: colors.neutral.gray[500],
      count: weeklyData.byDiscipline.autre.count,
      duration: weeklyData.byDiscipline.autre.duration,
      distance: weeklyData.byDiscipline.autre.distance,
    });
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Icon name="grid-outline" size={20} color={colors.primary[500]} />
        <Text style={styles.title}>Séances effectuées</Text>
      </View>

      {/* Grille des cartes */}
      <View style={styles.cardsGrid}>
        {cards.map(card => (
          <TouchableOpacity
            key={card.discipline}
            style={styles.card}
            onPress={() => onPressCard(card.discipline)}
            activeOpacity={0.7}
          >
            {/* Icône sport */}
            <View style={[styles.iconContainer, { backgroundColor: card.color + '20' }]}>
              <Icon name={card.icon} size={24} color={card.color} />
            </View>

            {/* Nom du sport */}
            <Text style={styles.sportName}>{card.name}</Text>

            {/* Stats */}
            <View style={styles.statsContainer}>
              {/* Nombre de séances */}
              <View style={styles.statRow}>
                <Icon name="layers-outline" size={12} color={colors.neutral.gray[400]} />
                <Text style={styles.statValue}>
                  {card.count} séance{card.count > 1 ? 's' : ''}
                </Text>
              </View>

              {/* Durée */}
              <View style={styles.statRow}>
                <Icon name="time-outline" size={12} color={colors.neutral.gray[400]} />
                <Text style={styles.statValue}>
                  {dashboardService.formatDuration(card.duration)}
                </Text>
              </View>

              {/* Distance */}
              {card.distance > 0 && (
                <View style={styles.statRow}>
                  <Icon name="navigate-outline" size={12} color={colors.neutral.gray[400]} />
                  <Text style={styles.statValue}>
                    {dashboardService.formatDistance(card.distance, card.discipline)}
                  </Text>
                </View>
              )}
            </View>

            {/* Indicateur de navigation */}
            <View style={styles.navIndicator}>
              <Icon name="chevron-forward" size={16} color={colors.neutral.gray[300]} />
            </View>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    // Pas de fond car les cartes ont leur propre fond
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
    marginBottom: spacing.md,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  cardsGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  card: {
    flex: 1,
    minWidth: '30%',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    alignItems: 'center',
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
    position: 'relative',
  },
  iconContainer: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  sportName: {
    ...typography.styles.label,
    color: colors.secondary[800],
    marginBottom: spacing.xs,
  },
  statsContainer: {
    width: '100%',
    gap: 2,
  },
  statRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
  },
  statValue: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontSize: 11,
  },
  navIndicator: {
    position: 'absolute',
    top: spacing.sm,
    right: spacing.sm,
  },
});

export default SportCardsWidget;
