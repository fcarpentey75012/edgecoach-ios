/**
 * Composant de notation du ressenti d'effort (1-5)
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

interface EffortRatingProps {
  value: number | null;
  onChange: (value: number) => void;
}

const EFFORT_LABELS = [
  { value: 1, label: 'Très facile', color: '#10B981' },
  { value: 2, label: 'Facile', color: '#34D399' },
  { value: 3, label: 'Modéré', color: '#FBBF24' },
  { value: 4, label: 'Difficile', color: '#F97316' },
  { value: 5, label: 'Très difficile', color: '#EF4444' },
];

const EffortRating: React.FC<EffortRatingProps> = ({ value, onChange }) => {
  const selectedLabel = value ? EFFORT_LABELS.find(e => e.value === value) : null;

  return (
    <View style={styles.container}>
      <View style={styles.starsContainer}>
        {EFFORT_LABELS.map(effort => (
          <TouchableOpacity
            key={effort.value}
            style={[
              styles.starButton,
              value === effort.value && { backgroundColor: effort.color + '20' },
            ]}
            onPress={() => onChange(effort.value)}
          >
            <Icon
              name={value && value >= effort.value ? 'star' : 'star-outline'}
              size={28}
              color={value && value >= effort.value ? effort.color : colors.neutral.gray[300]}
            />
          </TouchableOpacity>
        ))}
      </View>

      {selectedLabel && (
        <View style={[styles.labelContainer, { backgroundColor: selectedLabel.color + '15' }]}>
          <Text style={[styles.labelText, { color: selectedLabel.color }]}>
            {selectedLabel.label}
          </Text>
        </View>
      )}

      {!value && (
        <Text style={styles.hint}>Évaluez la difficulté ressentie</Text>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
  },
  starsContainer: {
    flexDirection: 'row',
    gap: spacing.xs,
  },
  starButton: {
    padding: spacing.sm,
    borderRadius: spacing.borderRadius.md,
  },
  labelContainer: {
    marginTop: spacing.md,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: spacing.borderRadius.full,
  },
  labelText: {
    ...typography.styles.label,
    fontWeight: '600',
  },
  hint: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: spacing.sm,
  },
});

export default EffortRating;
