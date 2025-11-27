/**
 * Écran de gestion de l'équipement sportif
 * Affiche et permet de gérer les vélos, chaussures, combinaisons, etc.
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  RefreshControl,
  Alert,
  Modal,
  TextInput,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation } from '@react-navigation/native';
import { useAuth } from '../contexts/AuthContext';
import {
  equipmentService,
  UserEquipment,
  EquipmentItem,
  AddEquipmentData,
} from '../services/equipmentService';
import { colors, spacing, typography } from '../theme';

type Sport = 'cycling' | 'running' | 'swimming';

interface CategoryInfo {
  key: string;
  label: string;
  icon: string;
}

interface SportConfig {
  id: Sport;
  label: string;
  icon: string;
  color: string;
  categories: CategoryInfo[];
}

const SPORTS_CONFIG: SportConfig[] = [
  {
    id: 'cycling',
    label: 'Vélo',
    icon: 'bicycle',
    color: colors.sports.cycling,
    categories: [
      { key: 'bikes', label: 'Vélos', icon: 'bicycle' },
      { key: 'shoes', label: 'Chaussures', icon: 'footsteps' },
      { key: 'accessories', label: 'Accessoires', icon: 'settings' },
    ],
  },
  {
    id: 'running',
    label: 'Course',
    icon: 'walk',
    color: colors.sports.running,
    categories: [
      { key: 'shoes', label: 'Chaussures', icon: 'footsteps' },
      { key: 'clothes', label: 'Vêtements', icon: 'shirt' },
      { key: 'accessories', label: 'Accessoires', icon: 'settings' },
    ],
  },
  {
    id: 'swimming',
    label: 'Natation',
    icon: 'water',
    color: colors.sports.swimming,
    categories: [
      { key: 'suits', label: 'Combinaisons', icon: 'body' },
      { key: 'goggles', label: 'Lunettes', icon: 'glasses' },
      { key: 'accessories', label: 'Accessoires', icon: 'settings' },
    ],
  },
];

const EquipmentScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user } = useAuth();

  const [selectedSport, setSelectedSport] = useState<Sport>('cycling');
  const [equipment, setEquipment] = useState<UserEquipment | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal d'ajout
  const [isAddModalVisible, setIsAddModalVisible] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [newItemName, setNewItemName] = useState('');
  const [newItemBrand, setNewItemBrand] = useState('');
  const [newItemModel, setNewItemModel] = useState('');
  const [isSaving, setIsSaving] = useState(false);

  // Charger l'équipement
  const loadEquipment = useCallback(async (forceRefresh = false) => {
    if (!user?.id) return;

    if (forceRefresh) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }
    setError(null);

    try {
      const result = await equipmentService.getEquipment(user.id);

      if (result.success && result.equipment) {
        setEquipment(result.equipment);
      } else {
        setError(result.error || 'Erreur lors du chargement');
      }
    } catch (err) {
      console.error('Error loading equipment:', err);
      setError('Erreur de connexion');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [user?.id]);

  useEffect(() => {
    loadEquipment();
  }, [loadEquipment]);

  // Obtenir la config du sport sélectionné
  const getCurrentSportConfig = (): SportConfig => {
    return SPORTS_CONFIG.find(s => s.id === selectedSport) || SPORTS_CONFIG[0];
  };

  // Obtenir les équipements du sport sélectionné
  const getCurrentEquipment = () => {
    if (!equipment) return null;
    return equipment[selectedSport];
  };

  // Ouvrir le modal d'ajout
  const openAddModal = (category: string) => {
    setSelectedCategory(category);
    setNewItemName('');
    setNewItemBrand('');
    setNewItemModel('');
    setIsAddModalVisible(true);
  };

  // Ajouter un équipement
  const handleAddEquipment = async () => {
    if (!user?.id || !selectedCategory || !newItemName.trim()) return;

    setIsSaving(true);
    try {
      const data: AddEquipmentData = {
        sport: selectedSport,
        category: selectedCategory,
        name: newItemName.trim(),
        brand: newItemBrand.trim() || undefined,
        model: newItemModel.trim() || undefined,
      };

      const result = await equipmentService.addEquipment(user.id, data);

      if (result.success) {
        setIsAddModalVisible(false);
        loadEquipment(true);
        Alert.alert('Succès', 'Équipement ajouté');
      } else {
        Alert.alert('Erreur', result.error || 'Impossible d\'ajouter');
      }
    } catch (err) {
      Alert.alert('Erreur', 'Erreur lors de l\'ajout');
    } finally {
      setIsSaving(false);
    }
  };

  // Supprimer un équipement
  const handleDeleteEquipment = (item: EquipmentItem, category: string) => {
    Alert.alert(
      'Supprimer',
      `Êtes-vous sûr de vouloir supprimer "${item.name}" ?`,
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Supprimer',
          style: 'destructive',
          onPress: async () => {
            if (!user?.id) return;

            try {
              const result = await equipmentService.deleteEquipment(
                user.id,
                selectedSport,
                category,
                item.id
              );

              if (result.success) {
                loadEquipment(true);
              } else {
                Alert.alert('Erreur', result.error || 'Impossible de supprimer');
              }
            } catch (err) {
              Alert.alert('Erreur', 'Erreur lors de la suppression');
            }
          },
        },
      ]
    );
  };

  // Rendu du sélecteur de sport
  const renderSportSelector = () => (
    <View style={styles.sportSelector}>
      {SPORTS_CONFIG.map((sport) => {
        const isSelected = selectedSport === sport.id;
        const count = equipment ? equipmentService.getEquipmentCount(equipment, sport.id) : 0;

        return (
          <TouchableOpacity
            key={sport.id}
            style={[
              styles.sportButton,
              isSelected && { backgroundColor: sport.color + '20', borderColor: sport.color },
            ]}
            onPress={() => setSelectedSport(sport.id)}
          >
            <Icon
              name={sport.icon}
              size={24}
              color={isSelected ? sport.color : colors.neutral.gray[500]}
            />
            <Text
              style={[
                styles.sportButtonText,
                isSelected && { color: sport.color },
              ]}
            >
              {sport.label}
            </Text>
            {count > 0 && (
              <View style={[styles.countBadge, { backgroundColor: sport.color }]}>
                <Text style={styles.countBadgeText}>{count}</Text>
              </View>
            )}
          </TouchableOpacity>
        );
      })}
    </View>
  );

  // Rendu d'un item d'équipement
  const renderEquipmentItem = (item: EquipmentItem, category: string) => {
    const sportConfig = getCurrentSportConfig();

    return (
      <View key={item.id} style={styles.equipmentItem}>
        <View style={[styles.equipmentItemIcon, { backgroundColor: sportConfig.color + '20' }]}>
          <Icon name={getCategoryIcon(category)} size={20} color={sportConfig.color} />
        </View>
        <View style={styles.equipmentItemContent}>
          <Text style={styles.equipmentItemName}>{item.name}</Text>
          {(item.brand || item.model) && (
            <Text style={styles.equipmentItemInfo}>
              {[item.brand, item.model].filter(Boolean).join(' ')}
            </Text>
          )}
          {item.year && (
            <Text style={styles.equipmentItemYear}>{item.year}</Text>
          )}
        </View>
        <View style={styles.equipmentItemActions}>
          {!item.isActive && (
            <View style={styles.inactiveBadge}>
              <Text style={styles.inactiveBadgeText}>Inactif</Text>
            </View>
          )}
          <TouchableOpacity
            style={styles.deleteButton}
            onPress={() => handleDeleteEquipment(item, category)}
          >
            <Icon name="trash-outline" size={18} color={colors.status.error} />
          </TouchableOpacity>
        </View>
      </View>
    );
  };

  // Obtenir l'icône d'une catégorie
  const getCategoryIcon = (categoryKey: string): string => {
    const sportConfig = getCurrentSportConfig();
    const category = sportConfig.categories.find(c => c.key === categoryKey);
    return category?.icon || 'cube-outline';
  };

  // Rendu d'une catégorie d'équipement
  const renderCategory = (categoryInfo: CategoryInfo) => {
    const currentEquipment = getCurrentEquipment();
    const items: EquipmentItem[] = currentEquipment?.[categoryInfo.key as keyof typeof currentEquipment] as EquipmentItem[] || [];
    const sportConfig = getCurrentSportConfig();

    return (
      <View key={categoryInfo.key} style={styles.categorySection}>
        <View style={styles.categoryHeader}>
          <View style={styles.categoryHeaderLeft}>
            <Icon name={categoryInfo.icon} size={20} color={sportConfig.color} />
            <Text style={styles.categoryTitle}>{categoryInfo.label}</Text>
            <Text style={styles.categoryCount}>({items.length})</Text>
          </View>
          <TouchableOpacity
            style={[styles.addButton, { backgroundColor: sportConfig.color }]}
            onPress={() => openAddModal(categoryInfo.key)}
          >
            <Icon name="add" size={18} color={colors.neutral.white} />
          </TouchableOpacity>
        </View>

        {items.length > 0 ? (
          <View style={styles.categoryItems}>
            {items.map((item) => renderEquipmentItem(item, categoryInfo.key))}
          </View>
        ) : (
          <View style={styles.emptyCategory}>
            <Text style={styles.emptyCategoryText}>
              Aucun {categoryInfo.label.toLowerCase()} enregistré
            </Text>
          </View>
        )}
      </View>
    );
  };

  // Modal d'ajout
  const renderAddModal = () => {
    const sportConfig = getCurrentSportConfig();
    const categoryInfo = sportConfig.categories.find(c => c.key === selectedCategory);

    return (
      <Modal
        visible={isAddModalVisible}
        animationType="slide"
        presentationStyle="pageSheet"
        onRequestClose={() => setIsAddModalVisible(false)}
      >
        <View style={styles.modalContainer}>
          <View style={styles.modalHeader}>
            <TouchableOpacity onPress={() => setIsAddModalVisible(false)}>
              <Text style={styles.modalCancel}>Annuler</Text>
            </TouchableOpacity>
            <Text style={styles.modalTitle}>
              Ajouter {categoryInfo?.label?.toLowerCase() || 'équipement'}
            </Text>
            <TouchableOpacity
              onPress={handleAddEquipment}
              disabled={!newItemName.trim() || isSaving}
            >
              {isSaving ? (
                <ActivityIndicator size="small" color={colors.primary[500]} />
              ) : (
                <Text
                  style={[
                    styles.modalSave,
                    !newItemName.trim() && styles.modalSaveDisabled,
                  ]}
                >
                  Ajouter
                </Text>
              )}
            </TouchableOpacity>
          </View>

          <ScrollView style={styles.modalContent}>
            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Nom *</Text>
              <TextInput
                style={styles.formInput}
                value={newItemName}
                onChangeText={setNewItemName}
                placeholder="Ex: Canyon Aeroad"
                placeholderTextColor={colors.neutral.gray[400]}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Marque</Text>
              <TextInput
                style={styles.formInput}
                value={newItemBrand}
                onChangeText={setNewItemBrand}
                placeholder="Ex: Canyon"
                placeholderTextColor={colors.neutral.gray[400]}
              />
            </View>

            <View style={styles.formGroup}>
              <Text style={styles.formLabel}>Modèle</Text>
              <TextInput
                style={styles.formInput}
                value={newItemModel}
                onChangeText={setNewItemModel}
                placeholder="Ex: CF SLX 8"
                placeholderTextColor={colors.neutral.gray[400]}
              />
            </View>
          </ScrollView>
        </View>
      </Modal>
    );
  };

  // Affichage pendant le chargement
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary[500]} />
        <Text style={styles.loadingText}>Chargement de l'équipement...</Text>
      </View>
    );
  }

  // Affichage en cas d'erreur
  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Icon name="alert-circle-outline" size={48} color={colors.status.error} />
        <Text style={styles.errorTitle}>Erreur</Text>
        <Text style={styles.errorText}>{error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={() => loadEquipment()}>
          <Text style={styles.retryButtonText}>Réessayer</Text>
        </TouchableOpacity>
      </View>
    );
  }

  const sportConfig = getCurrentSportConfig();

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity style={styles.backButton} onPress={() => navigation.goBack()}>
          <Icon name="arrow-back" size={24} color={colors.secondary[800]} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Mon équipement</Text>
        <View style={styles.headerSpacer} />
      </View>

      <ScrollView
        style={styles.scrollContent}
        contentContainerStyle={styles.scrollContentInner}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => loadEquipment(true)}
            colors={[colors.primary[500]]}
          />
        }
      >
        {/* Sélecteur de sport */}
        {renderSportSelector()}

        {/* Total équipements */}
        <View style={[styles.totalCard, { borderLeftColor: sportConfig.color }]}>
          <Text style={styles.totalLabel}>
            Équipements {sportConfig.label.toLowerCase()}
          </Text>
          <Text style={[styles.totalValue, { color: sportConfig.color }]}>
            {equipment ? equipmentService.getEquipmentCount(equipment, selectedSport) : 0}
          </Text>
        </View>

        {/* Catégories */}
        {sportConfig.categories.map((category) => renderCategory(category))}
      </ScrollView>

      {/* Modal d'ajout */}
      {renderAddModal()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: spacing.xl * 2,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.neutral.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
  },
  backButton: {
    padding: spacing.xs,
  },
  headerTitle: {
    ...typography.styles.h4,
    color: colors.secondary[800],
  },
  headerSpacer: {
    width: 32,
  },
  scrollContent: {
    flex: 1,
  },
  scrollContentInner: {
    padding: spacing.md,
    paddingBottom: spacing.xl * 2,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
  },
  loadingText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.md,
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.light.background,
    padding: spacing.xl,
  },
  errorTitle: {
    ...typography.styles.h4,
    color: colors.status.error,
    marginTop: spacing.md,
  },
  errorText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    textAlign: 'center',
    marginTop: spacing.sm,
  },
  retryButton: {
    backgroundColor: colors.primary[500],
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderRadius: spacing.borderRadius.md,
    marginTop: spacing.lg,
  },
  retryButtonText: {
    ...typography.styles.label,
    color: colors.neutral.white,
  },
  sportSelector: {
    flexDirection: 'row',
    gap: spacing.sm,
    marginBottom: spacing.lg,
  },
  sportButton: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    paddingVertical: spacing.md,
    borderRadius: spacing.borderRadius.md,
    borderWidth: 2,
    borderColor: 'transparent',
    gap: spacing.xs,
    position: 'relative',
  },
  sportButtonText: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    fontWeight: '600',
  },
  countBadge: {
    position: 'absolute',
    top: spacing.xs,
    right: spacing.xs,
    minWidth: 18,
    height: 18,
    borderRadius: 9,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  countBadgeText: {
    ...typography.styles.caption,
    fontSize: 10,
    color: colors.neutral.white,
    fontWeight: '700',
  },
  totalCard: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    marginBottom: spacing.lg,
    borderLeftWidth: 4,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  totalLabel: {
    ...typography.styles.label,
    color: colors.neutral.gray[600],
  },
  totalValue: {
    ...typography.styles.h3,
    fontWeight: '700',
  },
  categorySection: {
    marginBottom: spacing.lg,
  },
  categoryHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  categoryHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  categoryTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  categoryCount: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
  },
  addButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  categoryItems: {
    gap: spacing.sm,
  },
  equipmentItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
  },
  equipmentItemIcon: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  equipmentItemContent: {
    flex: 1,
  },
  equipmentItemName: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  equipmentItemInfo: {
    ...typography.styles.caption,
    color: colors.neutral.gray[600],
    marginTop: 2,
  },
  equipmentItemYear: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    marginTop: 2,
  },
  equipmentItemActions: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  inactiveBadge: {
    backgroundColor: colors.neutral.gray[200],
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: spacing.borderRadius.sm,
  },
  inactiveBadgeText: {
    ...typography.styles.caption,
    fontSize: 10,
    color: colors.neutral.gray[600],
  },
  deleteButton: {
    padding: spacing.xs,
  },
  emptyCategory: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.lg,
    alignItems: 'center',
  },
  emptyCategoryText: {
    ...typography.styles.body,
    color: colors.neutral.gray[400],
  },
  modalContainer: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: spacing.xl,
    paddingBottom: spacing.md,
    paddingHorizontal: spacing.md,
    backgroundColor: colors.neutral.white,
    borderBottomWidth: 1,
    borderBottomColor: colors.neutral.gray[200],
  },
  modalCancel: {
    ...typography.styles.body,
    color: colors.status.error,
  },
  modalTitle: {
    ...typography.styles.label,
    color: colors.secondary[800],
  },
  modalSave: {
    ...typography.styles.body,
    color: colors.primary[500],
    fontWeight: '600',
  },
  modalSaveDisabled: {
    color: colors.neutral.gray[400],
  },
  modalContent: {
    flex: 1,
    padding: spacing.md,
  },
  formGroup: {
    marginBottom: spacing.lg,
  },
  formLabel: {
    ...typography.styles.label,
    color: colors.secondary[700],
    marginBottom: spacing.xs,
  },
  formInput: {
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.md,
    padding: spacing.md,
    ...typography.styles.body,
    color: colors.secondary[800],
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
  },
});

export default EquipmentScreen;
