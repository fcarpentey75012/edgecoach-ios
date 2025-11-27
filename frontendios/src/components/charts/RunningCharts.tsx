/**
 * Graphiques spécifiques à la course à pied
 * Inclut: Allure, Cadence, Longueur de foulée, Puissance, GCT, Oscillation verticale
 * INTERACTIFS avec pointerConfig pour afficher les valeurs au toucher
 */

import React, { useMemo, useState } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { LineChart } from 'react-native-gifted-charts';
import { colors, spacing, typography } from '../../theme';

const SCREEN_WIDTH = Dimensions.get('window').width;

// Types pour les données de course
interface RunningDataPoint {
  Speed?: number;
  enhanced_speed?: number;
  speed?: number;
  cadence?: number;
  Cadence?: number;
  stance_time?: number;
  ground_contact_time?: number;
  vertical_oscillation?: number;
  VerticalOscillation?: number;
  power?: number;
  Watts?: number;
  stride_length?: number;
  distance?: number;
  time?: string;
  heart_rate?: number;
  altitude?: number;
  enhanced_altitude?: number;
}

// ============ UTILITAIRES ============

const speedToPace = (speedKmh: number): number => {
  if (!speedKmh || speedKmh <= 0) return 0;
  return 60 / speedKmh;
};

const formatPace = (paceMinKm: number): string => {
  if (!paceMinKm || paceMinKm <= 0 || paceMinKm > 20) return '--:--';
  const minutes = Math.floor(paceMinKm);
  const seconds = Math.round((paceMinKm - minutes) * 60);
  return `${minutes}:${seconds.toString().padStart(2, '0')}`;
};

const smoothData = (data: number[], windowSize: number = 5): number[] => {
  return data.map((_, index, arr) => {
    const start = Math.max(0, index - windowSize);
    const end = Math.min(arr.length - 1, index + windowSize);
    let sum = 0;
    let count = 0;
    for (let i = start; i <= end; i++) {
      if (arr[i] > 0) {
        sum += arr[i];
        count++;
      }
    }
    return count > 0 ? sum / count : 0;
  });
};

const sampleData = <T,>(data: T[], maxPoints: number = 100): T[] => {
  if (data.length <= maxPoints) return data;
  const sampleRate = Math.floor(data.length / maxPoints);
  return data.filter((_, index) => index % sampleRate === 0);
};

// ============ TOOLTIP COMPONENT ============

interface TooltipProps {
  value: string;
  label: string;
  color: string;
}

const Tooltip: React.FC<TooltipProps> = ({ value, label, color }) => (
  <View style={[tooltipStyles.container, { borderColor: color }]}>
    <Text style={[tooltipStyles.value, { color }]}>{value}</Text>
    <Text style={tooltipStyles.label}>{label}</Text>
  </View>
);

const tooltipStyles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.15,
    shadowRadius: 4,
    elevation: 4,
    alignItems: 'center',
    minWidth: 60,
  },
  value: {
    fontSize: 14,
    fontWeight: '700',
  },
  label: {
    fontSize: 10,
    color: colors.neutral.gray[500],
  },
});

// ============ COMPOSANT ALLURE ============

interface PaceGraphProps {
  recordData: RunningDataPoint[];
  avgPace?: string | null;
  bestPace?: string | null;
  compact?: boolean;
}

export const PaceGraph: React.FC<PaceGraphProps> = ({
  recordData,
  avgPace,
  bestPace,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<string | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 80);
    const paces = sampled.map(point => {
      const speedKmh = point.Speed || point.enhanced_speed || point.speed || 0;
      return speedKmh > 0 ? speedToPace(speedKmh) : 0;
    });

    const smoothed = smoothData(paces, 5);

    return smoothed
      .map(pace => {
        if (pace <= 2 || pace > 15) return null;
        return { value: pace, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Allure</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données d'allure</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = colors.sports.running;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Allure</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{focusedValue}/km</Text>
          ) : (
            <>
              {avgPace && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Moy</Text>
                  <Text style={styles.statValue}>{avgPace}/km</Text>
                </View>
              )}
              {bestPace && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Meilleur</Text>
                  <Text style={[styles.statValue, styles.bestValue]}>{bestPace}/km</Text>
                </View>
              )}
            </>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 120}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 120,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 80,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(formatPace(val));
              return (
                <Tooltip
                  value={formatPace(val)}
                  label="min/km"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir les valeurs • Plus bas = plus rapide</Text>
      </View>
    </View>
  );
};

// ============ COMPOSANT CADENCE ============

interface CadenceGraphProps {
  recordData: RunningDataPoint[];
  avgCadence?: number | null;
  maxCadence?: number | null;
  compact?: boolean;
}

export const CadenceGraph: React.FC<CadenceGraphProps> = ({
  recordData,
  avgCadence,
  maxCadence,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<number | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 100);
    const cadences = sampled.map(point => point.cadence || point.Cadence || 0);
    const smoothed = smoothData(cadences, 3);

    return smoothed
      .map(cad => {
        if (cad < 100 || cad > 220) return null;
        return { value: cad, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Cadence</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de cadence</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = '#8b5cf6';

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Cadence</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{Math.round(focusedValue)} ppm</Text>
          ) : (
            <>
              {avgCadence && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Moy</Text>
                  <Text style={styles.statValue}>{Math.round(avgCadence)} ppm</Text>
                </View>
              )}
              {maxCadence && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Max</Text>
                  <Text style={[styles.statValue, styles.maxValue]}>{Math.round(maxCadence)} ppm</Text>
                </View>
              )}
            </>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 100}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 100,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 80,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(val);
              return (
                <Tooltip
                  value={`${Math.round(val)}`}
                  label="ppm"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir les valeurs</Text>
      </View>
    </View>
  );
};

// ============ COMPOSANT PUISSANCE DE COURSE ============

interface RunningPowerGraphProps {
  recordData: RunningDataPoint[];
  avgPower?: number | null;
  maxPower?: number | null;
  compact?: boolean;
}

export const RunningPowerGraph: React.FC<RunningPowerGraphProps> = ({
  recordData,
  avgPower,
  maxPower,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<number | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 100);
    const powers = sampled.map(point => point.power || point.Watts || 0);
    const smoothed = smoothData(powers, 3);

    return smoothed
      .map(power => {
        if (power <= 0 || power > 1000) return null;
        return { value: power, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Puissance</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de puissance</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = colors.status.warning;

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Puissance</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{Math.round(focusedValue)}W</Text>
          ) : (
            <>
              {avgPower && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Moy</Text>
                  <Text style={styles.statValue}>{Math.round(avgPower)}W</Text>
                </View>
              )}
              {maxPower && (
                <View style={styles.stat}>
                  <Text style={styles.statLabel}>Max</Text>
                  <Text style={[styles.statValue, styles.maxValue]}>{Math.round(maxPower)}W</Text>
                </View>
              )}
            </>
          )}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 100}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 100,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 70,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(val);
              return (
                <Tooltip
                  value={`${Math.round(val)}`}
                  label="watts"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir les valeurs</Text>
      </View>
    </View>
  );
};

// ============ COMPOSANT TEMPS DE CONTACT AU SOL (GCT) ============

interface GroundContactTimeGraphProps {
  recordData: RunningDataPoint[];
  avgGCT?: number | null;
  compact?: boolean;
}

export const GroundContactTimeGraph: React.FC<GroundContactTimeGraphProps> = ({
  recordData,
  avgGCT,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<number | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 100);
    const gcts = sampled.map(point => point.stance_time || point.ground_contact_time || 0);
    const smoothed = smoothData(gcts, 3);

    return smoothed
      .map(gct => {
        if (gct < 150 || gct > 400) return null;
        return { value: gct, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Temps au sol</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données GCT</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = '#06b6d4';

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Temps au sol (GCT)</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{Math.round(focusedValue)} ms</Text>
          ) : avgGCT ? (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{Math.round(avgGCT)} ms</Text>
            </View>
          ) : null}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 100}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 100,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 70,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(val);
              return (
                <Tooltip
                  value={`${Math.round(val)}`}
                  label="ms"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir • Plus bas = meilleure efficacité</Text>
      </View>
    </View>
  );
};

// ============ COMPOSANT OSCILLATION VERTICALE ============

interface VerticalOscillationGraphProps {
  recordData: RunningDataPoint[];
  avgVO?: number | null;
  compact?: boolean;
}

export const VerticalOscillationGraph: React.FC<VerticalOscillationGraphProps> = ({
  recordData,
  avgVO,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<number | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 100);
    const vos = sampled.map(point => point.vertical_oscillation || point.VerticalOscillation || 0);
    const smoothed = smoothData(vos, 3);

    return smoothed
      .map(vo => {
        if (vo < 3 || vo > 15) return null;
        return { value: vo, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Oscillation verticale</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données d'oscillation</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = '#ec4899';

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Oscillation verticale</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{focusedValue.toFixed(1)} cm</Text>
          ) : avgVO ? (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgVO.toFixed(1)} cm</Text>
            </View>
          ) : null}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 100}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 100,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 70,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(val);
              return (
                <Tooltip
                  value={val.toFixed(1)}
                  label="cm"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir • Plus bas = meilleure efficacité</Text>
      </View>
    </View>
  );
};

// ============ COMPOSANT LONGUEUR DE FOULÉE ============

interface StrideLengthGraphProps {
  recordData: RunningDataPoint[];
  avgStrideLength?: number | null;
  compact?: boolean;
}

export const StrideLengthGraph: React.FC<StrideLengthGraphProps> = ({
  recordData,
  avgStrideLength,
  compact = false,
}) => {
  const [focusedValue, setFocusedValue] = useState<number | null>(null);

  const chartData = useMemo(() => {
    if (!recordData || recordData.length === 0) return [];

    const sampled = sampleData(recordData, 100);

    const strides = sampled.map(point => {
      if (point.stride_length && point.stride_length > 0) {
        return point.stride_length;
      }
      const speedKmh = point.Speed || point.enhanced_speed || point.speed || 0;
      const cadence = point.cadence || point.Cadence || 0;
      if (speedKmh > 0 && cadence > 0) {
        const speedMs = speedKmh / 3.6;
        const cadencePerSecond = cadence / 60;
        return speedMs / (cadencePerSecond / 2);
      }
      return 0;
    });

    const smoothed = smoothData(strides, 3);

    return smoothed
      .map(stride => {
        if (stride < 0.5 || stride > 2.5) return null;
        return { value: stride, dataPointText: '' };
      })
      .filter((p): p is { value: number; dataPointText: string } => p !== null);
  }, [recordData]);

  if (chartData.length === 0) {
    return (
      <View style={[styles.container, compact && styles.containerCompact]}>
        <Text style={styles.title}>Longueur de foulée</Text>
        <View style={styles.noDataContainer}>
          <Text style={styles.noDataText}>Pas de données de foulée</Text>
        </View>
      </View>
    );
  }

  const chartWidth = SCREEN_WIDTH - spacing.md * 4;
  const chartColor = '#10b981';

  return (
    <View style={[styles.container, compact && styles.containerCompact]}>
      <View style={styles.header}>
        <Text style={styles.title}>Longueur de foulée</Text>
        <View style={styles.statsRow}>
          {focusedValue ? (
            <Text style={[styles.focusedValue, { color: chartColor }]}>{focusedValue.toFixed(2)} m</Text>
          ) : avgStrideLength ? (
            <View style={styles.stat}>
              <Text style={styles.statLabel}>Moy</Text>
              <Text style={styles.statValue}>{avgStrideLength.toFixed(2)} m</Text>
            </View>
          ) : null}
        </View>
      </View>

      <View style={styles.chartContainer}>
        <LineChart
          data={chartData}
          width={chartWidth}
          height={compact ? 80 : 100}
          color={chartColor}
          areaChart
          startFillColor={chartColor + '40'}
          endFillColor={chartColor + '10'}
          hideDataPoints
          curved
          thickness={2}
          hideYAxisText
          hideAxesAndRules
          adjustToWidth
          initialSpacing={0}
          endSpacing={0}
          pointerConfig={{
            pointerStripHeight: compact ? 80 : 100,
            pointerStripColor: chartColor,
            pointerStripWidth: 2,
            pointerColor: chartColor,
            radius: 6,
            pointerLabelWidth: 70,
            pointerLabelHeight: 40,
            activatePointersOnLongPress: false,
            autoAdjustPointerLabelPosition: true,
            pointerLabelComponent: (items: any) => {
              const val = items[0]?.value;
              if (val) setFocusedValue(val);
              return (
                <Tooltip
                  value={val.toFixed(2)}
                  label="mètres"
                  color={chartColor}
                />
              );
            },
          }}
          onEndReached={() => setFocusedValue(null)}
        />
        <Text style={styles.axisNote}>Glissez pour voir les valeurs</Text>
      </View>
    </View>
  );
};

// ============ STYLES ============

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  containerCompact: {
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  title: {
    ...typography.styles.label,
    color: colors.secondary[800],
    fontWeight: '600',
  },
  statsRow: {
    flexDirection: 'row',
    gap: spacing.md,
  },
  stat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.xs,
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  statValue: {
    ...typography.styles.label,
    fontWeight: '700',
    color: colors.secondary[800],
  },
  focusedValue: {
    ...typography.styles.label,
    fontWeight: '700',
    fontSize: 16,
  },
  bestValue: {
    color: colors.status.success,
  },
  maxValue: {
    color: colors.status.error,
  },
  chartContainer: {
    alignItems: 'center',
    overflow: 'hidden',
  },
  axisNote: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    fontSize: 10,
    marginTop: spacing.xs,
    textAlign: 'center',
  },
  noDataContainer: {
    height: 80,
    justifyContent: 'center',
    alignItems: 'center',
  },
  noDataText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
  },
});

export default {
  PaceGraph,
  CadenceGraph,
  RunningPowerGraph,
  GroundContactTimeGraph,
  VerticalOscillationGraph,
  StrideLengthGraph,
};
