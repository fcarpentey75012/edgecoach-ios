/**
 * Widget donut de répartition du temps par sport
 * Affiche un pie chart avec la distribution des entraînements
 */

import React, { useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
} from 'react-native';
import { PieChart } from 'react-native-gifted-charts';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { WeeklySummaryData, dashboardService } from '../../services';

interface SportDistributionWidgetProps {
  weeklyData: WeeklySummaryData | null;
}

interface SportData {
  name: string;
  icon: string;
  duration: number;
  color: string;
}

const SportDistributionWidget: React.FC<SportDistributionWidgetProps> = ({
  weeklyData,
}) => {
  // Préparer les données pour le donut
  const sportData = useMemo((): SportData[] => {
    if (!weeklyData) {
      return [];
    }

    const data: SportData[] = [
      {
        name: 'Vélo',
        icon: 'bicycle',
        duration: weeklyData.byDiscipline.cyclisme.duration,
        color: colors.sports.cycling,
      },
      {
        name: 'Course',
        icon: 'walk',
        duration: weeklyData.byDiscipline.course.duration,
        color: colors.sports.running,
      },
      {
        name: 'Natation',
        icon: 'water',
        duration: weeklyData.byDiscipline.natation.duration,
        color: colors.sports.swimming,
      },
      {
        name: 'Autre',
        icon: 'fitness',
        duration: weeklyData.byDiscipline.autre.duration,
        color: colors.neutral.gray[400],
      },
    ];

    // Filtrer les sports avec du temps
    return data.filter(sport => sport.duration > 0);
  }, [weeklyData]);

  // Données pour le pie chart
  const pieData = useMemo(() => {
    const total = sportData.reduce((sum, sport) => sum + sport.duration, 0);

    return sportData.map(sport => ({
      value: sport.duration,
      color: sport.color,
      text: `${Math.round((sport.duration / total) * 100)}%`,
      gradientCenterColor: sport.color,
    }));
  }, [sportData]);

  // Temps total
  const totalDuration = useMemo(() => {
    if (!weeklyData) return '0h';
    return dashboardService.formatDuration(weeklyData.summary.totalDuration);
  }, [weeklyData]);

  // Si pas de données
  if (sportData.length === 0) {
    return (
      <View style={styles.container}>
        <View style={styles.header}>
          <Icon name="pie-chart-outline" size={20} color={colors.primary[500]} />
          <Text style={styles.title}>Répartition</Text>
        </View>
        <View style={styles.emptyState}>
          <Icon name="analytics-outline" size={40} color={colors.neutral.gray[300]} />
          <Text style={styles.emptyText}>Pas de données cette semaine</Text>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Icon name="pie-chart-outline" size={20} color={colors.primary[500]} />
          <Text style={styles.title}>Répartition</Text>
        </View>
      </View>

      {/* Contenu */}
      <View style={styles.content}>
        {/* Donut Chart */}
        <View style={styles.chartWrapper}>
          <PieChart
            data={pieData}
            donut
            radius={55}
            innerRadius={35}
            innerCircleColor={colors.neutral.white}
            centerLabelComponent={() => (
              <View style={styles.centerLabel}>
                <Text style={styles.centerValue}>{totalDuration}</Text>
                <Text style={styles.centerText}>Total</Text>
              </View>
            )}
          />
        </View>

        {/* Légende */}
        <View style={styles.legend}>
          {sportData.map((sport, index) => {
            const percentage = Math.round(
              (sport.duration / sportData.reduce((s, d) => s + d.duration, 0)) * 100
            );
            return (
              <View key={sport.name} style={styles.legendItem}>
                <View style={styles.legendLeft}>
                  <View style={[styles.legendDot, { backgroundColor: sport.color }]} />
                  <Icon name={sport.icon} size={14} color={sport.color} />
                  <Text style={styles.legendName}>{sport.name}</Text>
                </View>
                <View style={styles.legendRight}>
                  <Text style={styles.legendDuration}>
                    {dashboardService.formatDuration(sport.duration)}
                  </Text>
                  <Text style={styles.legendPercent}>{percentage}%</Text>
                </View>
              </View>
            );
          })}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  content: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  chartWrapper: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  centerLabel: {
    alignItems: 'center',
  },
  centerValue: {
    ...typography.styles.h4,
    color: colors.secondary[800],
    fontSize: 14,
  },
  centerText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 10,
  },
  legend: {
    flex: 1,
    gap: spacing.sm,
  },
  legendItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  legendLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendName: {
    ...typography.styles.bodySmall,
    color: colors.secondary[700],
  },
  legendRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  legendDuration: {
    ...typography.styles.caption,
    color: colors.secondary[600],
    fontWeight: '500',
  },
  legendPercent: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    minWidth: 30,
    textAlign: 'right',
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing.lg,
    gap: spacing.sm,
  },
  emptyText: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[400],
  },
});

export default SportDistributionWidget;
