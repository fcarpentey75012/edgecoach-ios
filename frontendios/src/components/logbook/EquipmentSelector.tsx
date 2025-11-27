/**
 * Composant de sélection d'équipement pour le carnet d'entraînement
 * Permet de sélectionner vélo, chaussures selon la discipline
 */

import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  Pressable,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { equipmentService, EquipmentItem, UserEquipment } from '../../services/equipmentService';
import { SessionEquipment } from '../../services/logbookService';
import { colors, spacing, typography } from '../../theme';

interface EquipmentSelectorProps {
  userId: string;
  discipline: 'cyclisme' | 'course' | 'natation' | 'autre';
  selectedEquipment: SessionEquipment;
  onEquipmentChange: (equipment: SessionEquipment) => void;
}

type EquipmentCategory = 'bikes' | 'shoes' | 'suits';

interface CategoryConfig {
  key: EquipmentCategory;
  label: string;
  icon: string;
  sportKey: 'cycling' | 'running' | 'swimming';
}

const EquipmentSelector: React.FC<EquipmentSelectorProps> = ({
  userId,
  discipline,
  selectedEquipment,
  onEquipmentChange,
}) => {
  const [equipment, setEquipment] = useState<UserEquipment | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [modalCategory, setModalCategory] = useState<CategoryConfig | null>(null);

  // Charger l'équipement de l'utilisateur
  useEffect(() => {
    const loadEquipment = async () => {
      if (!userId) return;
      setIsLoading(true);
      try {
        const result = await equipmentService.getEquipment(userId);
        if (result.success && result.equipment) {
          setEquipment(result.equipment);
        }
      } catch (error) {
        console.error('Erreur chargement équipement:', error);
      } finally {
        setIsLoading(false);
      }
    };
    loadEquipment();
  }, [userId]);

  // Configuration des catégories selon la discipline
  const getCategories = (): CategoryConfig[] => {
    switch (discipline) {
      case 'cyclisme':
        return [
          { key: 'bikes', label: 'Vélo', icon: 'bicycle', sportKey: 'cycling' },
          { key: 'shoes', label: 'Chaussures', icon: 'footsteps', sportKey: 'cycling' },
        ];
      case 'course':
        return [
          { key: 'shoes', label: 'Chaussures', icon: 'footsteps', sportKey: 'running' },
        ];
      case 'natation':
        return [
          { key: 'suits', label: 'Combinaison', icon: 'body', sportKey: 'swimming' },
        ];
      default:
        return [];
    }
  };

  // Obtenir les items d'une catégorie
  const getCategoryItems = (config: CategoryConfig): EquipmentItem[] => {
    if (!equipment) return [];
    const sportEquipment = equipment[config.sportKey];
    if (!sportEquipment) return [];
    const items = sportEquipment[config.key as keyof typeof sportEquipment];
    return Array.isArray(items) ? items.filter(item => item.isActive) : [];
  };

  // Obtenir l'item sélectionné
  const getSelectedItem = (category: EquipmentCategory): EquipmentItem | undefined => {
    const selectedId = selectedEquipment[category];
    if (!selectedId || !equipment) return undefined;

    // Chercher dans tous les sports
    for (const sport of ['cycling', 'running', 'swimming'] as const) {
      const sportEquipment = equipment[sport];
      if (sportEquipment) {
        const items = sportEquipment[category as keyof typeof sportEquipment];
        if (Array.isArray(items)) {
          const found = items.find(item => item.id === selectedId);
          if (found) return found;
        }
      }
    }
    return undefined;
  };

  // Sélectionner un équipement
  const selectEquipment = (category: EquipmentCategory, itemId: string | undefined) => {
    onEquipmentChange({
      ...selectedEquipment,
      [category]: itemId,
    });
    setModalCategory(null);
  };

  const categories = getCategories();

  if (categories.length === 0) {
    return null;
  }

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="small" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement équipement...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {categories.map(config => {
        const items = getCategoryItems(config);
        const selectedItem = getSelectedItem(config.key);

        return (
          <TouchableOpacity
            key={config.key}
            style={styles.selectorRow}
            onPress={() => setModalCategory(config)}
          >
            <View style={styles.selectorIcon}>
              <Icon name={config.icon} size={20} color={colors.primary[500]} />
            </View>
            <View style={styles.selectorInfo}>
              <Text style={styles.selectorLabel}>{config.label}</Text>
              {selectedItem ? (
                <Text style={styles.selectorValue}>
                  {selectedItem.brand} {selectedItem.name}
                </Text>
              ) : (
                <Text style={styles.selectorPlaceholder}>
                  {items.length > 0 ? 'Non sélectionné' : 'Aucun équipement'}
                </Text>
              )}
            </View>
            <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
          </TouchableOpacity>
        );
      })}

      {/* Modal de sélection */}
      <Modal
        visible={modalCategory !== null}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setModalCategory(null)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>
              Sélectionner {modalCategory?.label.toLowerCase()}
            </Text>
            <Pressable onPress={() => setModalCategory(null)}>
              <Icon name="close" size={24} color={colors.secondary[800]} />
            </Pressable>
          </View>

          <ScrollView style={styles.itemsList}>
            {/* Option "Aucun" */}
            <TouchableOpacity
              style={[
                styles.itemRow,
                !selectedEquipment[modalCategory?.key || 'bikes'] && styles.itemRowSelected,
              ]}
              onPress={() => selectEquipment(modalCategory!.key, undefined)}
            >
              <View style={styles.itemIconPlaceholder}>
                <Icon name="close-circle-outline" size={24} color={colors.neutral.gray[400]} />
              </View>
              <View style={styles.itemInfo}>
                <Text style={styles.itemName}>Aucun</Text>
                <Text style={styles.itemDetails}>Ne pas enregistrer d'équipement</Text>
              </View>
              {!selectedEquipment[modalCategory?.key || 'bikes'] && (
                <Icon name="checkmark-circle" size={24} color={colors.primary[500]} />
              )}
            </TouchableOpacity>

            {/* Liste des équipements */}
            {modalCategory && getCategoryItems(modalCategory).map(item => {
              const isSelected = selectedEquipment[modalCategory.key] === item.id;

              return (
                <TouchableOpacity
                  key={item.id}
                  style={[styles.itemRow, isSelected && styles.itemRowSelected]}
                  onPress={() => selectEquipment(modalCategory.key, item.id)}
                >
                  <View style={[styles.itemIcon, { backgroundColor: colors.primary[100] }]}>
                    <Icon name={modalCategory.icon} size={20} color={colors.primary[600]} />
                  </View>
                  <View style={styles.itemInfo}>
                    <Text style={styles.itemName}>
                      {item.brand} {item.name}
                    </Text>
                    {item.model && (
                      <Text style={styles.itemDetails}>{item.model}</Text>
                    )}
                  </View>
                  {isSelected && (
                    <Icon name="checkmark-circle" size={24} color={colors.primary[500]} />
                  )}
                </TouchableOpacity>
              );
            })}

            {/* Message si pas d'équipement */}
            {modalCategory && getCategoryItems(modalCategory).length === 0 && (
              <View style={styles.emptyState}>
                <Icon name="cube-outline" size={48} color={colors.neutral.gray[300]} />
                <Text style={styles.emptyTitle}>Aucun équipement</Text>
                <Text style={styles.emptyText}>
                  Ajoutez votre équipement dans les paramètres du profil
                </Text>
              </View>
            )}
          </ScrollView>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {},
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.md,
    gap: spacing.sm,
  },
  loadingText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  selectorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.xs,
  },
  selectorIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    backgroundColor: colors.primary[100],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  selectorInfo: {
    flex: 1,
  },
  selectorLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginBottom: 2,
  },
  selectorValue: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  selectorPlaceholder: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
    fontStyle: 'italic',
  },
  modalContainer: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: spacing.md,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
    backgroundColor: colors.neutral.white,
  },
  modalTitle: {
    ...typography.styles.h3,
    color: colors.secondary[800],
  },
  itemsList: {
    padding: spacing.md,
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  itemRowSelected: {
    backgroundColor: colors.primary[50],
    borderWidth: 1,
    borderColor: colors.primary[300],
  },
  itemIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  itemIconPlaceholder: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.neutral.gray[100],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  itemInfo: {
    flex: 1,
  },
  itemName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  itemDetails: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: 2,
  },
  emptyState: {
    alignItems: 'center',
    paddingVertical: spacing.xl * 2,
  },
  emptyTitle: {
    ...typography.styles.h4,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  emptyText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.xs,
    paddingHorizontal: spacing.lg,
  },
});

export default EquipmentSelector;
