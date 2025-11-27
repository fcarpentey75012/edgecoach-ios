/**
 * Composant de métriques avancées par sport
 * Affiche des métriques spécialisées selon la discipline
 */

import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { colors, spacing, typography } from '../../theme';
import { Activity } from '../../services/activitiesService';

interface AdvancedMetricsProps {
  activity: Activity;
  sportColor: string;
}

interface MetricItemProps {
  icon: string;
  iconColor: string;
  label: string;
  value: string | number;
  unit?: string;
  description?: string;
}

const MetricItem: React.FC<MetricItemProps> = ({
  icon,
  iconColor,
  label,
  value,
  unit,
  description,
}) => (
  <View style={styles.metricItem}>
    <View style={[styles.metricIconContainer, { backgroundColor: iconColor + '15' }]}>
      <Icon name={icon} size={18} color={iconColor} />
    </View>
    <View style={styles.metricContent}>
      <Text style={styles.metricLabel}>{label}</Text>
      <View style={styles.metricValueRow}>
        <Text style={styles.metricValue}>{value}</Text>
        {unit && <Text style={styles.metricUnit}>{unit}</Text>}
      </View>
      {description && <Text style={styles.metricDescription}>{description}</Text>}
    </View>
  </View>
);

// Convertir km/h en min/km
const kmhToMinKm = (speedKmh: number): string => {
  if (!speedKmh || speedKmh <= 0) return '--:--';
  const minPerKm = 60 / speedKmh;
  const minutes = Math.floor(minPerKm);
  const seconds = Math.round((minPerKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

// Convertir km/h en min/100m
const kmhToMin100m = (speedKmh: number): string => {
  if (!speedKmh || speedKmh <= 0) return '--:--';
  const minPer100m = 6 / speedKmh;
  const minutes = Math.floor(minPer100m);
  const seconds = Math.round((minPer100m - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

// Estimer la longueur de foulée (course)
const estimateStrideLength = (distanceKm: number | null, durationSeconds: number | null, cadence: number | null): number | null => {
  if (!distanceKm || !durationSeconds || !cadence) return null;
  // Distance en mètres / (cadence * durée en minutes)
  const durationMinutes = durationSeconds / 60;
  const totalSteps = cadence * durationMinutes;
  const distanceMeters = distanceKm * 1000;
  return distanceMeters / totalSteps;
};

// Calculer le Variability Index (VI = NP / Avg Power)
const calculateVI = (np: number | null, avgPower: number | null): number | null => {
  if (!np || !avgPower || avgPower === 0) return null;
  return np / avgPower;
};

const CyclingMetrics: React.FC<{ activity: Activity; sportColor: string }> = ({
  activity,
  sportColor,
}) => {
  const fileData = activity.fileData as any;
  const avgPower = fileData?.avg_power || activity.avgWatt;
  const np = fileData?.np || activity.normalizedPower;
  const intensityFactor = fileData?.if_;
  const tss = fileData?.tss || activity.loadCoggan;
  const cadence = fileData?.cadence_avg;
  const kilojoules = activity.kilojoules;
  const vi = calculateVI(np, avgPower);

  const hasMetrics = avgPower || np || intensityFactor || tss || cadence;

  if (!hasMetrics) return null;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Icon name="bicycle" size={20} color={sportColor} />
        <Text style={styles.headerTitle}>Métriques Cyclisme</Text>
      </View>

      <View style={styles.metricsGrid}>
        {avgPower && (
          <MetricItem
            icon="flash-outline"
            iconColor={colors.status.warning}
            label="Puissance moy."
            value={Math.round(avgPower)}
            unit="W"
          />
        )}
        {np && (
          <MetricItem
            icon="pulse-outline"
            iconColor={colors.sports.cycling}
            label="Puissance Norm."
            value={Math.round(np)}
            unit="W"
            description="Intensité pondérée"
          />
        )}
        {vi && (
          <MetricItem
            icon="analytics-outline"
            iconColor={colors.primary[500]}
            label="Variability Index"
            value={vi.toFixed(2)}
            description={vi > 1.05 ? 'Effort variable' : 'Effort régulier'}
          />
        )}
        {intensityFactor && (
          <MetricItem
            icon="speedometer-outline"
            iconColor={colors.primary[600]}
            label="Intensity Factor"
            value={intensityFactor.toFixed(2)}
            description={getIFDescription(intensityFactor)}
          />
        )}
        {tss && (
          <MetricItem
            icon="barbell-outline"
            iconColor={colors.status.error}
            label="Training Stress"
            value={Math.round(tss)}
            unit="TSS"
            description={getTSSDescription(tss)}
          />
        )}
        {cadence && (
          <MetricItem
            icon="sync-outline"
            iconColor={colors.sports.running}
            label="Cadence moy."
            value={Math.round(cadence)}
            unit="rpm"
          />
        )}
        {kilojoules && (
          <MetricItem
            icon="battery-charging-outline"
            iconColor={colors.status.success}
            label="Travail"
            value={Math.round(kilojoules)}
            unit="kJ"
            description={`~${Math.round(kilojoules * 0.25)} kcal`}
          />
        )}
      </View>
    </View>
  );
};

const RunningMetrics: React.FC<{ activity: Activity; sportColor: string }> = ({
  activity,
  sportColor,
}) => {
  const fileData = activity.fileData as any;
  const avgSpeed = fileData?.avg_speed;
  const avgSpeedMoving = fileData?.avg_speed_moving_kmh;
  const cadence = fileData?.cadence_avg;
  const elevationGain = activity.elevationGain;
  const tss = activity.loadCoggan;

  // Parser la distance
  const distanceKm = activity.distance
    ? parseFloat(activity.distance.replace(/[^\d.]/g, ''))
    : null;

  // Parser la durée en secondes
  const durationSeconds = activity.duration
    ? parseDurationToSeconds(activity.duration)
    : null;

  // Calculer la longueur de foulée estimée
  const strideLength = estimateStrideLength(distanceKm, durationSeconds, cadence);

  const hasMetrics = avgSpeed || avgSpeedMoving || cadence || elevationGain;

  if (!hasMetrics) return null;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Icon name="walk" size={20} color={sportColor} />
        <Text style={styles.headerTitle}>Métriques Course</Text>
      </View>

      <View style={styles.metricsGrid}>
        {avgSpeed && (
          <MetricItem
            icon="speedometer-outline"
            iconColor={colors.sports.running}
            label="Allure moyenne"
            value={kmhToMinKm(avgSpeed)}
            unit="min/km"
          />
        )}
        {avgSpeedMoving && avgSpeedMoving !== avgSpeed && (
          <MetricItem
            icon="play-outline"
            iconColor={colors.primary[500]}
            label="Allure en mvt"
            value={kmhToMinKm(avgSpeedMoving)}
            unit="min/km"
            description="Sans les pauses"
          />
        )}
        {cadence && (
          <MetricItem
            icon="footsteps-outline"
            iconColor={colors.status.warning}
            label="Cadence moy."
            value={Math.round(cadence)}
            unit="pas/min"
            description={getCadenceDescription(cadence)}
          />
        )}
        {strideLength && (
          <MetricItem
            icon="resize-outline"
            iconColor={colors.sports.swimming}
            label="Foulée estimée"
            value={strideLength.toFixed(2)}
            unit="m"
          />
        )}
        {elevationGain && elevationGain > 50 && distanceKm && (
          <MetricItem
            icon="trending-up-outline"
            iconColor={colors.status.error}
            label="Gradient moy."
            value={((elevationGain / (distanceKm * 1000)) * 100).toFixed(1)}
            unit="%"
            description={`D+ ${elevationGain}m`}
          />
        )}
        {tss && (
          <MetricItem
            icon="barbell-outline"
            iconColor={colors.status.error}
            label="Training Stress"
            value={Math.round(tss)}
            unit="TSS"
            description={getTSSDescription(tss)}
          />
        )}
      </View>
    </View>
  );
};

const SwimmingMetrics: React.FC<{ activity: Activity; sportColor: string }> = ({
  activity,
  sportColor,
}) => {
  const fileData = activity.fileData as any;
  const avgSpeed = fileData?.avg_speed;

  // Parser la distance (en mètres pour natation)
  const distanceStr = activity.distance;
  const distanceM = distanceStr
    ? parseFloat(distanceStr.replace(/[^\d.]/g, '')) * (distanceStr.includes('km') ? 1000 : 1)
    : null;

  // Parser la durée
  const durationSeconds = activity.duration
    ? parseDurationToSeconds(activity.duration)
    : null;

  // Calculer le temps aux 100m
  const timePer100m = distanceM && durationSeconds && distanceM > 0
    ? (durationSeconds / distanceM) * 100
    : null;

  const hasMetrics = avgSpeed || timePer100m;

  if (!hasMetrics) return null;

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Icon name="water" size={20} color={sportColor} />
        <Text style={styles.headerTitle}>Métriques Natation</Text>
      </View>

      <View style={styles.metricsGrid}>
        {timePer100m && (
          <MetricItem
            icon="timer-outline"
            iconColor={colors.sports.swimming}
            label="Temps aux 100m"
            value={formatSecondsToMinSec(timePer100m)}
            unit="/100m"
          />
        )}
        {avgSpeed && (
          <MetricItem
            icon="speedometer-outline"
            iconColor={colors.primary[500]}
            label="Allure moyenne"
            value={kmhToMin100m(avgSpeed)}
            unit="/100m"
          />
        )}
      </View>
    </View>
  );
};

// Helpers
const parseDurationToSeconds = (duration: string): number | null => {
  // Format "Xmin"
  const minMatch = duration.match(/^(\d+)min$/);
  if (minMatch) {
    return parseInt(minMatch[1], 10) * 60;
  }

  // Format "H:MM"
  const hourMinMatch = duration.match(/^(\d+):(\d+)$/);
  if (hourMinMatch) {
    return parseInt(hourMinMatch[1], 10) * 3600 + parseInt(hourMinMatch[2], 10) * 60;
  }

  return null;
};

const formatSecondsToMinSec = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = Math.round(seconds % 60);
  return `${mins}:${secs.toString().padStart(2, '0')}`;
};

const getIFDescription = (if_: number): string => {
  if (if_ < 0.55) return 'Récupération';
  if (if_ < 0.75) return 'Endurance';
  if (if_ < 0.90) return 'Tempo';
  if (if_ < 1.05) return 'Seuil';
  return 'Haute intensité';
};

const getTSSDescription = (tss: number): string => {
  if (tss < 100) return 'Récup rapide';
  if (tss < 200) return 'Fatigue modérée';
  if (tss < 300) return 'Fatigue importante';
  return 'Très éprouvant';
};

const getCadenceDescription = (cadence: number): string => {
  if (cadence < 160) return 'Cadence basse';
  if (cadence < 180) return 'Cadence normale';
  return 'Cadence élevée';
};

const AdvancedMetrics: React.FC<AdvancedMetricsProps> = ({ activity, sportColor }) => {
  switch (activity.discipline) {
    case 'cyclisme':
      return <CyclingMetrics activity={activity} sportColor={sportColor} />;
    case 'course':
      return <RunningMetrics activity={activity} sportColor={sportColor} />;
    case 'natation':
      return <SwimmingMetrics activity={activity} sportColor={sportColor} />;
    default:
      return null;
  }
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginTop: spacing.md,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: spacing.md,
    paddingBottom: spacing.sm,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[100],
  },
  headerTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  metricsGrid: {
    gap: spacing.sm,
  },
  metricItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing.sm,
    paddingVertical: spacing.xs,
  },
  metricIconContainer: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  metricContent: {
    flex: 1,
  },
  metricLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  metricValueRow: {
    flexDirection: 'row',
    alignItems: 'baseline',
    gap: 4,
  },
  metricValue: {
    ...typography.styles.h4,
    color: colors.secondary[800],
  },
  metricUnit: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  metricDescription: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontSize: 10,
    marginTop: 2,
  },
});

export default AdvancedMetrics;
