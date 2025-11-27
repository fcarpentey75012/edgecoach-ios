/**
 * Widget graphique du volume d'entraînement sur 7 jours
 * Affiche un bar chart avec toggle Durée/Distance/Calories
 */

import React, { useState, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Dimensions,
} from 'react-native';
import { BarChart } from 'react-native-gifted-charts';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { WeeklySummaryData } from '../../services';

const { width: SCREEN_WIDTH } = Dimensions.get('window');

type MetricType = 'duration' | 'distance' | 'calories';

interface DayData {
  day: string;
  shortDay: string;
  duration: number; // minutes
  distance: number; // km
  calories: number;
}

interface WeeklyVolumeChartProps {
  weeklyData: WeeklySummaryData | null;
  dailyData?: DayData[];
}

const DAYS_FR = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

// Données de démo si pas de données réelles
const generateDemoData = (): DayData[] => {
  return DAYS_FR.map((day, index) => ({
    day: day,
    shortDay: day.charAt(0),
    duration: Math.floor(Math.random() * 90) + 15,
    distance: Math.floor(Math.random() * 30) + 5,
    calories: Math.floor(Math.random() * 600) + 200,
  }));
};

const WeeklyVolumeChart: React.FC<WeeklyVolumeChartProps> = ({
  weeklyData,
  dailyData,
}) => {
  const [selectedMetric, setSelectedMetric] = useState<MetricType>('duration');

  // Utiliser les données fournies ou générer des données de démo
  const chartDailyData = useMemo(() => {
    if (dailyData && dailyData.length > 0) {
      return dailyData;
    }
    // Pour l'instant, générer des données de démo basées sur weeklyData
    if (weeklyData) {
      const avgDuration = weeklyData.summary.totalDuration / 7 / 60; // minutes par jour
      const avgDistance = weeklyData.summary.totalDistance / 7 / 1000; // km par jour
      const avgCalories = weeklyData.summary.totalCalories / 7;

      return DAYS_FR.map((day, index) => {
        // Variation aléatoire autour de la moyenne
        const variation = 0.5 + Math.random();
        return {
          day,
          shortDay: day.charAt(0),
          duration: Math.max(0, Math.floor(avgDuration * variation)),
          distance: Math.max(0, parseFloat((avgDistance * variation).toFixed(1))),
          calories: Math.max(0, Math.floor(avgCalories * variation)),
        };
      });
    }
    return generateDemoData();
  }, [dailyData, weeklyData]);

  // Préparer les données pour le graphique
  const barData = useMemo(() => {
    return chartDailyData.map((day, index) => {
      let value = 0;
      switch (selectedMetric) {
        case 'duration':
          value = day.duration;
          break;
        case 'distance':
          value = day.distance;
          break;
        case 'calories':
          value = day.calories;
          break;
      }

      // Couleur basée sur le jour (aujourd'hui = primary)
      const today = new Date().getDay();
      const adjustedToday = today === 0 ? 6 : today - 1; // Lundi = 0
      const isToday = index === adjustedToday;

      return {
        value,
        label: day.shortDay,
        frontColor: isToday ? colors.primary[500] : colors.primary[300],
        topLabelComponent: () => (
          <Text style={styles.barTopLabel}>
            {selectedMetric === 'duration'
              ? `${value}`
              : selectedMetric === 'distance'
              ? `${value}`
              : `${value}`}
          </Text>
        ),
      };
    });
  }, [chartDailyData, selectedMetric]);

  // Calcul du max pour l'échelle
  const maxValue = useMemo(() => {
    const values = barData.map(d => d.value);
    return Math.max(...values, 1);
  }, [barData]);

  // Formater la valeur totale
  const totalValue = useMemo(() => {
    const total = chartDailyData.reduce((sum, day) => {
      switch (selectedMetric) {
        case 'duration':
          return sum + day.duration;
        case 'distance':
          return sum + day.distance;
        case 'calories':
          return sum + day.calories;
      }
    }, 0);

    switch (selectedMetric) {
      case 'duration':
        const hours = Math.floor(total / 60);
        const mins = total % 60;
        return hours > 0 ? `${hours}h${mins.toString().padStart(2, '0')}` : `${mins}min`;
      case 'distance':
        return `${total.toFixed(1)} km`;
      case 'calories':
        return `${total} kcal`;
    }
  }, [chartDailyData, selectedMetric]);

  const metricConfig = {
    duration: { label: 'Durée', icon: 'time-outline', unit: 'min' },
    distance: { label: 'Distance', icon: 'navigate-outline', unit: 'km' },
    calories: { label: 'Calories', icon: 'flame-outline', unit: 'kcal' },
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.titleContainer}>
          <Icon name="bar-chart-outline" size={20} color={colors.primary[500]} />
          <Text style={styles.title}>Volume 7 jours</Text>
        </View>
        <Text style={styles.totalValue}>{totalValue}</Text>
      </View>

      {/* Toggle boutons */}
      <View style={styles.toggleContainer}>
        {(Object.keys(metricConfig) as MetricType[]).map(metric => (
          <TouchableOpacity
            key={metric}
            style={[
              styles.toggleButton,
              selectedMetric === metric && styles.toggleButtonActive,
            ]}
            onPress={() => setSelectedMetric(metric)}
          >
            <Icon
              name={metricConfig[metric].icon}
              size={14}
              color={
                selectedMetric === metric
                  ? colors.primary[600]
                  : colors.neutral.gray[500]
              }
            />
            <Text
              style={[
                styles.toggleText,
                selectedMetric === metric && styles.toggleTextActive,
              ]}
            >
              {metricConfig[metric].label}
            </Text>
          </TouchableOpacity>
        ))}
      </View>

      {/* Graphique */}
      <View style={styles.chartContainer}>
        <BarChart
          data={barData}
          height={100}
          barWidth={28}
          spacing={12}
          initialSpacing={10}
          endSpacing={10}
          barBorderRadius={4}
          hideRules
          hideYAxisText
          hideAxesAndRules
          xAxisLabelTextStyle={styles.xAxisLabel}
          noOfSections={4}
          maxValue={maxValue * 1.2}
          isAnimated
          animationDuration={500}
        />
      </View>

      {/* Légende */}
      <View style={styles.legend}>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: colors.primary[500] }]} />
          <Text style={styles.legendText}>Aujourd'hui</Text>
        </View>
        <View style={styles.legendItem}>
          <View style={[styles.legendDot, { backgroundColor: colors.primary[300] }]} />
          <Text style={styles.legendText}>Cette semaine</Text>
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
    marginBottom: spacing.sm,
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
  totalValue: {
    ...typography.styles.h4,
    color: colors.primary[600],
  },
  toggleContainer: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.gray[100],
    borderRadius: spacing.borderRadius.md,
    padding: 3,
    marginBottom: spacing.md,
  },
  toggleButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.sm,
    borderRadius: spacing.borderRadius.sm,
    gap: 4,
  },
  toggleButtonActive: {
    backgroundColor: colors.neutral.white,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 1,
  },
  toggleText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  toggleTextActive: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  chartContainer: {
    alignItems: 'center',
    overflow: 'hidden',
  },
  xAxisLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    fontSize: 11,
  },
  barTopLabel: {
    ...typography.styles.caption,
    color: colors.secondary[700],
    fontSize: 9,
    marginBottom: 2,
  },
  legend: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: spacing.lg,
    marginTop: spacing.sm,
  },
  legendItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
});

export default WeeklyVolumeChart;
