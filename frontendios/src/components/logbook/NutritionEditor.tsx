/**
 * Composant d'édition de la nutrition pendant l'effort
 * Permet d'ajouter des gels avec leur timing
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput,
  Modal,
  Pressable,
  Image,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { gelsData, Gel, getGelById } from '../../data/gelsData';
import { NutritionItem } from '../../services/logbookService';
import { colors, spacing, typography } from '../../theme';

interface NutritionEditorProps {
  items: NutritionItem[];
  onItemsChange: (items: NutritionItem[]) => void;
}

const NutritionEditor: React.FC<NutritionEditorProps> = ({ items, onItemsChange }) => {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [editingTimingId, setEditingTimingId] = useState<string | null>(null);

  // Calculer les totaux
  const totals = items.reduce(
    (acc, item) => ({
      calories: acc.calories + item.calories * item.quantity,
      carbs: acc.carbs + item.carbs * item.quantity,
      caffeine: acc.caffeine + item.caffeine * item.quantity,
    }),
    { calories: 0, carbs: 0, caffeine: 0 }
  );

  // Formater le timing en "0h30" pour l'API
  const formatTimingForApi = (minutes: number | undefined): string => {
    if (minutes === undefined) return '';
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return `${h}h${m.toString().padStart(2, '0')}`;
  };

  // Ajouter un gel
  const addGel = (gel: Gel) => {
    const newItem: NutritionItem = {
      uniqueId: `${gel.id}-${Date.now()}`,
      brand: gel.brand,
      name: gel.name,
      type: 'gel',
      calories: gel.calories,
      carbs: gel.carbs,
      caffeine: gel.caffeine,
      quantity: 1,
      timingMinutes: undefined,
      timingFormatted: '',
    };
    onItemsChange([...items, newItem]);
    setIsModalVisible(false);
  };

  // Supprimer un item
  const removeItem = (uniqueId: string) => {
    onItemsChange(items.filter(item => item.uniqueId !== uniqueId));
  };

  // Mettre à jour le timing
  const updateTiming = (uniqueId: string, timing: string) => {
    const minutes = parseInt(timing, 10);
    const validMinutes = isNaN(minutes) ? undefined : minutes;
    onItemsChange(
      items.map(item =>
        item.uniqueId === uniqueId
          ? {
              ...item,
              timingMinutes: validMinutes,
              timingFormatted: formatTimingForApi(validMinutes),
            }
          : item
      )
    );
  };

  // Formater le timing
  const formatTiming = (minutes: number): string => {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return h > 0 ? `${h}h${m.toString().padStart(2, '0')}` : `${m}min`;
  };

  return (
    <View style={styles.container}>
      {/* Totaux */}
      {items.length > 0 && (
        <View style={styles.totalsContainer}>
          <View style={styles.totalItem}>
            <Text style={styles.totalValue}>{totals.calories}</Text>
            <Text style={styles.totalLabel}>kcal</Text>
          </View>
          <View style={styles.totalDivider} />
          <View style={styles.totalItem}>
            <Text style={styles.totalValue}>{totals.carbs}g</Text>
            <Text style={styles.totalLabel}>glucides</Text>
          </View>
          <View style={styles.totalDivider} />
          <View style={styles.totalItem}>
            <Text style={styles.totalValue}>{totals.caffeine}mg</Text>
            <Text style={styles.totalLabel}>caféine</Text>
          </View>
        </View>
      )}

      {/* Liste des items ajoutés */}
      {items.map(item => {
        // Récupérer l'image du gel depuis les données
        const gelId = item.uniqueId.split('-').slice(0, -1).join('-'); // Enlever le timestamp
        const gel = getGelById(gelId);

        return (
          <View key={item.uniqueId} style={styles.itemRow}>
            {/* Image du gel */}
            {gel?.image ? (
              <Image source={gel.image} style={styles.itemImage} resizeMode="contain" />
            ) : (
              <View style={[styles.itemImagePlaceholder, { backgroundColor: gel?.color || colors.primary[100] }]}>
                <Icon name="nutrition" size={16} color={colors.neutral.white} />
              </View>
            )}

            <View style={styles.itemInfo}>
              <Text style={styles.itemName}>
                {item.brand} {item.name}
              </Text>
              <Text style={styles.itemDetails}>
                {item.calories} kcal • {item.carbs}g glucides
                {item.caffeine > 0 && ` • ${item.caffeine}mg caféine`}
              </Text>
            </View>

            {/* Timing */}
            <TouchableOpacity
              style={styles.timingButton}
              onPress={() => setEditingTimingId(editingTimingId === item.uniqueId ? null : item.uniqueId)}
            >
              <Icon name="time-outline" size={14} color={colors.primary[500]} />
              <Text style={styles.timingText}>
                {item.timingMinutes !== undefined ? formatTiming(item.timingMinutes) : 'Timing'}
              </Text>
            </TouchableOpacity>

            {/* Supprimer */}
            <TouchableOpacity
              style={styles.removeButton}
              onPress={() => removeItem(item.uniqueId)}
            >
              <Icon name="close-circle" size={22} color={colors.status.error} />
            </TouchableOpacity>
          </View>
        );
      })}

      {/* Input de timing si édition */}
      {editingTimingId && (
        <View style={styles.timingInputContainer}>
          <Text style={styles.timingInputLabel}>Timing (minutes depuis le début) :</Text>
          <TextInput
            style={styles.timingInput}
            keyboardType="number-pad"
            placeholder="ex: 45"
            placeholderTextColor={colors.neutral.gray[400]}
            value={
              items.find(i => i.uniqueId === editingTimingId)?.timingMinutes?.toString() || ''
            }
            onChangeText={text => updateTiming(editingTimingId, text)}
            onBlur={() => setEditingTimingId(null)}
            autoFocus
          />
        </View>
      )}

      {/* Bouton Ajouter */}
      <TouchableOpacity
        style={styles.addButton}
        onPress={() => setIsModalVisible(true)}
      >
        <Icon name="add-circle-outline" size={20} color={colors.primary[500]} />
        <Text style={styles.addButtonText}>Ajouter un gel</Text>
      </TouchableOpacity>

      {/* Modal de sélection */}
      <Modal
        visible={isModalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setIsModalVisible(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>Choisir un gel</Text>
            <Pressable onPress={() => setIsModalVisible(false)}>
              <Icon name="close" size={24} color={colors.secondary[800]} />
            </Pressable>
          </View>

          <ScrollView style={styles.gelsList}>
            {gelsData.map(gel => (
              <TouchableOpacity
                key={gel.id}
                style={styles.gelItem}
                onPress={() => addGel(gel)}
              >
                {/* Image du gel */}
                {gel.image ? (
                  <Image source={gel.image} style={styles.gelImage} resizeMode="contain" />
                ) : (
                  <View style={[styles.gelImagePlaceholder, { backgroundColor: gel.color }]}>
                    <Icon name="nutrition" size={20} color={colors.neutral.white} />
                  </View>
                )}
                <View style={styles.gelInfo}>
                  <Text style={styles.gelName}>{gel.brand} {gel.name}</Text>
                  <Text style={styles.gelDetails}>
                    {gel.calories} kcal • {gel.carbs}g glucides
                    {gel.caffeine > 0 && ` • ${gel.caffeine}mg caféine`}
                  </Text>
                </View>
                <Icon name="add" size={24} color={colors.primary[500]} />
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {},
  totalsContainer: {
    flexDirection: 'row',
    backgroundColor: colors.status.warning + '15',
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  totalItem: {
    flex: 1,
    alignItems: 'center',
  },
  totalDivider: {
    width: 1,
    backgroundColor: colors.status.warning + '30',
  },
  totalValue: {
    ...typography.styles.h4,
    color: colors.secondary[800],
  },
  totalLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  itemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.sm,
    marginBottom: spacing.xs,
  },
  itemImage: {
    width: 36,
    height: 36,
    marginRight: spacing.sm,
    borderRadius: spacing.borderRadius.sm,
  },
  itemImagePlaceholder: {
    width: 36,
    height: 36,
    marginRight: spacing.sm,
    borderRadius: spacing.borderRadius.sm,
    justifyContent: 'center',
    alignItems: 'center',
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
  timingButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    paddingHorizontal: spacing.sm,
    paddingVertical: spacing.xs,
    borderRadius: spacing.borderRadius.sm,
    marginRight: spacing.sm,
    gap: 4,
  },
  timingText: {
    ...typography.styles.caption,
    color: colors.primary[600],
    fontWeight: '500',
  },
  removeButton: {
    padding: spacing.xs,
  },
  timingInputContainer: {
    backgroundColor: colors.primary[50],
    borderRadius: spacing.borderRadius.md,
    padding: spacing.sm,
    marginBottom: spacing.sm,
  },
  timingInputLabel: {
    ...typography.styles.caption,
    color: colors.primary[700],
    marginBottom: spacing.xs,
  },
  timingInput: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.sm,
    padding: spacing.sm,
    ...typography.styles.body,
    color: colors.secondary[800],
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.primary[300],
    borderStyle: 'dashed',
    borderRadius: spacing.borderRadius.md,
    gap: spacing.xs,
    marginTop: spacing.sm,
  },
  addButtonText: {
    ...typography.styles.label,
    color: colors.primary[500],
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
  gelsList: {
    padding: spacing.md,
  },
  gelItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  gelImage: {
    width: 48,
    height: 48,
    marginRight: spacing.md,
    borderRadius: spacing.borderRadius.sm,
  },
  gelImagePlaceholder: {
    width: 48,
    height: 48,
    marginRight: spacing.md,
    borderRadius: spacing.borderRadius.sm,
    justifyContent: 'center',
    alignItems: 'center',
  },
  gelInfo: {
    flex: 1,
  },
  gelName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  gelDetails: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: 2,
  },
});

export default NutritionEditor;
