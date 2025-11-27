/**
 * Composant de sélection du coach
 * Affiche un dropdown avec tous les coachs disponibles par sport
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  FlatList,
  Pressable,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import {
  Coach,
  Sport,
  getAllCoaches,
  sportColors,
  sportLabels,
  sportIcons,
} from '../data/coaches';
import { coachService, SelectedCoach } from '../services/coachService';
import { useAuth } from '../contexts/AuthContext';
import { colors, spacing, typography } from '../theme';

interface CoachSelectorProps {
  onCoachChange?: (coach: SelectedCoach) => void;
}

const CoachSelector: React.FC<CoachSelectorProps> = ({ onCoachChange }) => {
  const { user } = useAuth();
  const [selectedCoach, setSelectedCoach] = useState<SelectedCoach | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const allCoaches = getAllCoaches();

  useEffect(() => {
    // Charger le coach initial
    const loadCoach = async () => {
      const coach = await coachService.initialize();
      setSelectedCoach(coach);
    };
    loadCoach();

    // Écouter les changements
    const unsubscribe = coachService.addListener((coach) => {
      setSelectedCoach(coach);
    });

    return unsubscribe;
  }, []);

  const handleSelectCoach = async (coach: Coach & { sport: Sport }) => {
    const success = await coachService.selectCoach(coach.sport, coach.id, user?.id);
    if (success) {
      const newSelectedCoach = coachService.getCurrentCoach();
      setSelectedCoach(newSelectedCoach);
      onCoachChange?.(newSelectedCoach);
    }
    setIsModalVisible(false);
  };

  const renderCoachItem = ({ item }: { item: Coach & { sport: Sport } }) => {
    const isSelected = selectedCoach?.id === item.id && selectedCoach?.sport === item.sport;
    const sportColor = sportColors[item.sport];

    return (
      <TouchableOpacity
        style={[styles.coachItem, isSelected && styles.coachItemSelected]}
        onPress={() => handleSelectCoach(item)}
        activeOpacity={0.7}
      >
        <View style={[styles.coachAvatar, { backgroundColor: sportColor + '20' }]}>
          <Text style={[styles.coachAvatarText, { color: sportColor }]}>
            {item.avatar}
          </Text>
        </View>
        <View style={styles.coachInfo}>
          <View style={styles.coachNameRow}>
            <Text style={styles.coachName}>{item.name}</Text>
            <View style={[styles.sportBadge, { backgroundColor: sportColor + '20' }]}>
              <Icon name={sportIcons[item.sport]} size={12} color={sportColor} />
              <Text style={[styles.sportBadgeText, { color: sportColor }]}>
                {sportLabels[item.sport]}
              </Text>
            </View>
          </View>
          <Text style={styles.coachSpeciality}>{item.speciality}</Text>
          <Text style={styles.coachDescription} numberOfLines={1}>
            {item.description}
          </Text>
        </View>
        {isSelected && (
          <Icon name="checkmark-circle" size={24} color={colors.primary[500]} />
        )}
      </TouchableOpacity>
    );
  };

  if (!selectedCoach) {
    return null;
  }

  const sportColor = sportColors[selectedCoach.sport];

  return (
    <>
      <TouchableOpacity
        style={styles.selectorButton}
        onPress={() => setIsModalVisible(true)}
        activeOpacity={0.7}
      >
        <View style={[styles.miniAvatar, { backgroundColor: sportColor + '20' }]}>
          <Text style={[styles.miniAvatarText, { color: sportColor }]}>
            {selectedCoach.avatar}
          </Text>
        </View>
        <View style={styles.selectorInfo}>
          <Text style={styles.selectorName}>{selectedCoach.name}</Text>
          <Text style={styles.selectorSport}>{sportLabels[selectedCoach.sport]}</Text>
        </View>
        <Icon name="chevron-down" size={16} color={colors.neutral.gray[500]} />
      </TouchableOpacity>

      <Modal
        visible={isModalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setIsModalVisible(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Choisir un coach</Text>
            <Pressable
              style={styles.closeButton}
              onPress={() => setIsModalVisible(false)}
            >
              <Icon name="close" size={24} color={colors.secondary[800]} />
            </Pressable>
          </View>

          <FlatList
            data={allCoaches}
            renderItem={renderCoachItem}
            keyExtractor={(item) => `${item.sport}-${item.id}`}
            contentContainerStyle={styles.coachList}
            showsVerticalScrollIndicator={false}
          />
        </View>
      </Modal>
    </>
  );
};

const styles = StyleSheet.create({
  selectorButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.lg,
    gap: spacing.sm,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
  },
  miniAvatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  miniAvatarText: {
    fontSize: 12,
    fontWeight: '700',
  },
  selectorInfo: {
    flex: 1,
  },
  selectorName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  selectorSport: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  modalContainer: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
    backgroundColor: colors.neutral.white,
  },
  modalTitle: {
    ...typography.styles.h3,
    color: colors.secondary[800],
  },
  closeButton: {
    padding: spacing.xs,
  },
  coachList: {
    padding: spacing.md,
  },
  coachItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    padding: spacing.md,
    borderRadius: spacing.borderRadius.lg,
    marginBottom: spacing.sm,
    gap: spacing.md,
  },
  coachItemSelected: {
    borderWidth: 2,
    borderColor: colors.primary[500],
  },
  coachAvatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
  },
  coachAvatarText: {
    fontSize: 16,
    fontWeight: '700',
  },
  coachInfo: {
    flex: 1,
  },
  coachNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
    marginBottom: 2,
  },
  coachName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  sportBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.sm,
    gap: 4,
  },
  sportBadgeText: {
    fontSize: 10,
    fontWeight: '600',
  },
  coachSpeciality: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    marginBottom: 2,
  },
  coachDescription: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
  },
});

export default CoachSelector;
