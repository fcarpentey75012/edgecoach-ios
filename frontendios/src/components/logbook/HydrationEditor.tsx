/**
 * Composant d'édition de l'hydratation pendant l'effort
 * Permet d'ajouter des bidons avec leur contenu
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  Modal,
  Pressable,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import {
  hydrationOptions,
  hydrationContentTypes,
  HydrationOption,
  HydrationContentType,
} from '../../data/hydrationData';
import { HydrationItem } from '../../services/logbookService';
import { colors, spacing, typography } from '../../theme';

interface HydrationEditorProps {
  items: HydrationItem[];
  onItemsChange: (items: HydrationItem[]) => void;
}

const HydrationEditor: React.FC<HydrationEditorProps> = ({ items, onItemsChange }) => {
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [selectedOption, setSelectedOption] = useState<HydrationOption | null>(null);

  // Calculer le volume total
  const totalVolume = items.reduce(
    (total, item) => total + item.volume * item.quantity,
    0
  );

  // Ajouter un bidon
  const addHydration = (option: HydrationOption, contentType: HydrationContentType) => {
    const newItem: HydrationItem = {
      id: `${option.id}-${contentType.id}-${Date.now()}`,
      name: `${option.name} - ${contentType.name}`,
      content: contentType.id, // 'water', 'electrolytes', 'isotonic', 'energy', 'bcaa'
      quantity: 1,
      volume: option.volume,
    };
    onItemsChange([...items, newItem]);
    setIsModalVisible(false);
    setSelectedOption(null);
  };

  // Supprimer un item
  const removeItem = (id: string) => {
    onItemsChange(items.filter(item => item.id !== id));
  };

  // Incrémenter/décrémenter la quantité
  const updateQuantity = (id: string, delta: number) => {
    onItemsChange(
      items.map(item => {
        if (item.id === id) {
          const newQuantity = Math.max(1, item.quantity + delta);
          return { ...item, quantity: newQuantity };
        }
        return item;
      })
    );
  };

  // Obtenir la couleur du type de contenu
  const getContentColor = (content: string): string => {
    const contentType = hydrationContentTypes.find(ct => ct.id === content);
    return contentType?.color || colors.sports.swimming;
  };

  // Obtenir le nom du type de contenu
  const getContentName = (content: string): string => {
    const contentType = hydrationContentTypes.find(ct => ct.id === content);
    return contentType?.name || content;
  };

  return (
    <View style={styles.container}>
      {/* Volume total */}
      {items.length > 0 && (
        <View style={styles.totalContainer}>
          <Icon name="water" size={24} color={colors.sports.swimming} />
          <Text style={styles.totalValue}>{totalVolume} ml</Text>
          <Text style={styles.totalLabel}>Volume total</Text>
        </View>
      )}

      {/* Liste des items ajoutés */}
      {items.map(item => (
        <View key={item.id} style={styles.itemRow}>
          <View style={[styles.itemColor, { backgroundColor: getContentColor(item.content) }]} />
          <View style={styles.itemInfo}>
            <Text style={styles.itemName}>{item.volume}ml</Text>
            <Text style={styles.itemType}>{getContentName(item.content)}</Text>
          </View>

          {/* Quantité */}
          <View style={styles.quantityControls}>
            <TouchableOpacity
              style={styles.quantityButton}
              onPress={() => updateQuantity(item.id, -1)}
            >
              <Icon name="remove" size={16} color={colors.secondary[800]} />
            </TouchableOpacity>
            <Text style={styles.quantityText}>{item.quantity}</Text>
            <TouchableOpacity
              style={styles.quantityButton}
              onPress={() => updateQuantity(item.id, 1)}
            >
              <Icon name="add" size={16} color={colors.secondary[800]} />
            </TouchableOpacity>
          </View>

          {/* Supprimer */}
          <TouchableOpacity
            style={styles.removeButton}
            onPress={() => removeItem(item.id)}
          >
            <Icon name="close-circle" size={22} color={colors.status.error} />
          </TouchableOpacity>
        </View>
      ))}

      {/* Bouton Ajouter */}
      <TouchableOpacity
        style={styles.addButton}
        onPress={() => setIsModalVisible(true)}
      >
        <Icon name="add-circle-outline" size={20} color={colors.sports.swimming} />
        <Text style={styles.addButtonText}>Ajouter hydratation</Text>
      </TouchableOpacity>

      {/* Modal de sélection */}
      <Modal
        visible={isModalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => {
          setIsModalVisible(false);
          setSelectedOption(null);
        }}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <Text style={styles.modalTitle}>
              {selectedOption ? 'Type de contenu' : 'Choisir un contenant'}
            </Text>
            <Pressable
              onPress={() => {
                if (selectedOption) {
                  setSelectedOption(null);
                } else {
                  setIsModalVisible(false);
                }
              }}
            >
              <Icon
                name={selectedOption ? 'arrow-back' : 'close'}
                size={24}
                color={colors.secondary[800]}
              />
            </Pressable>
          </View>

          {!selectedOption ? (
            // Étape 1 : Choisir le contenant
            <View style={styles.optionsList}>
              {hydrationOptions.map(option => (
                <TouchableOpacity
                  key={option.id}
                  style={styles.optionItem}
                  onPress={() => setSelectedOption(option)}
                >
                  <View style={styles.optionIcon}>
                    <Icon name={option.icon} size={32} color={colors.sports.swimming} />
                  </View>
                  <Text style={styles.optionName}>{option.name}</Text>
                  <Text style={styles.optionVolume}>{option.volume}ml</Text>
                  <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
                </TouchableOpacity>
              ))}
            </View>
          ) : (
            // Étape 2 : Choisir le type de contenu
            <View style={styles.optionsList}>
              <Text style={styles.selectedOptionLabel}>
                {selectedOption.name} ({selectedOption.volume}ml)
              </Text>
              {hydrationContentTypes.map(contentType => (
                <TouchableOpacity
                  key={contentType.id}
                  style={styles.contentTypeItem}
                  onPress={() => addHydration(selectedOption, contentType)}
                >
                  <View
                    style={[styles.contentTypeColor, { backgroundColor: contentType.color }]}
                  />
                  <Text style={styles.contentTypeName}>{contentType.name}</Text>
                  <Icon name="add" size={24} color={colors.primary[500]} />
                </TouchableOpacity>
              ))}
            </View>
          )}
        </View>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {},
  totalContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.sports.swimming + '15',
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.md,
    gap: spacing.sm,
  },
  totalValue: {
    ...typography.styles.h3,
    color: colors.sports.swimming,
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
  itemColor: {
    width: 6,
    height: 36,
    borderRadius: 3,
    marginRight: spacing.sm,
  },
  itemInfo: {
    flex: 1,
  },
  itemName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  itemType: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  quantityControls: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    marginRight: spacing.sm,
  },
  quantityButton: {
    padding: spacing.sm,
  },
  quantityText: {
    ...typography.styles.label,
    color: colors.secondary[800],
    minWidth: 24,
    textAlign: 'center',
  },
  removeButton: {
    padding: spacing.xs,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing.md,
    borderWidth: 1,
    borderColor: colors.sports.swimming + '50',
    borderStyle: 'dashed',
    borderRadius: spacing.borderRadius.md,
    gap: spacing.xs,
    marginTop: spacing.sm,
  },
  addButtonText: {
    ...typography.styles.label,
    color: colors.sports.swimming,
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
  optionsList: {
    padding: spacing.md,
  },
  optionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  optionIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    backgroundColor: colors.sports.swimming + '15',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  optionName: {
    flex: 1,
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  optionVolume: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginRight: spacing.sm,
  },
  selectedOptionLabel: {
    ...typography.styles.body,
    color: colors.neutral.gray[600],
    marginBottom: spacing.md,
    textAlign: 'center',
  },
  contentTypeItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  contentTypeColor: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: spacing.md,
  },
  contentTypeName: {
    flex: 1,
    ...typography.styles.label,
    color: colors.secondary[800],
  },
});

export default HydrationEditor;
