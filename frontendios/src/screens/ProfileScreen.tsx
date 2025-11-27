/**
 * Écran Profil utilisateur
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useNavigation, CompositeNavigationProp } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import { BottomTabNavigationProp } from '@react-navigation/bottom-tabs';
import { useAuth } from '../contexts/AuthContext';
import { RootStackParamList, MainTabParamList } from '../navigation/types';
import { equipmentService } from '../services/equipmentService';
import { colors, spacing, typography } from '../theme';

// Type composite pour naviguer depuis un Tab vers un écran du Stack parent
type ProfileNavigationProp = CompositeNavigationProp<
  BottomTabNavigationProp<MainTabParamList, 'Profile'>,
  NativeStackNavigationProp<RootStackParamList>
>;

// Niveaux d'expérience
const EXPERIENCE_LABELS: Record<string, string> = {
  beginner: 'Débutant',
  intermediate: 'Intermédiaire',
  advanced: 'Avancé',
  expert: 'Expert',
};

const ProfileScreen: React.FC = () => {
  const navigation = useNavigation<ProfileNavigationProp>();
  const { user, logout } = useAuth();
  const [equipmentCount, setEquipmentCount] = useState(0);
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Charger le nombre d'équipements
  const loadEquipmentCount = useCallback(async () => {
    if (!user?.id) return;
    try {
      const result = await equipmentService.getEquipment(user.id);
      if (result.success && result.equipment) {
        setEquipmentCount(equipmentService.getEquipmentCount(result.equipment));
      }
    } catch (error) {
      console.error('Error loading equipment count:', error);
    }
  }, [user?.id]);

  useEffect(() => {
    loadEquipmentCount();
  }, [loadEquipmentCount]);

  const onRefresh = async () => {
    setIsRefreshing(true);
    await loadEquipmentCount();
    setIsRefreshing(false);
  };

  const handleLogout = () => {
    Alert.alert(
      'Déconnexion',
      'Êtes-vous sûr de vouloir vous déconnecter ?',
      [
        { text: 'Annuler', style: 'cancel' },
        {
          text: 'Déconnexion',
          style: 'destructive',
          onPress: () => logout(),
        },
      ]
    );
  };

  const getInitials = () => {
    const first = user?.firstName?.charAt(0) || '';
    const last = user?.lastName?.charAt(0) || '';
    return (first + last).toUpperCase() || '?';
  };

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.content}
      refreshControl={
        <RefreshControl
          refreshing={isRefreshing}
          onRefresh={onRefresh}
          colors={[colors.primary[500]]}
        />
      }
    >
      {/* Profile Header */}
      <View style={styles.profileHeader}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>{getInitials()}</Text>
        </View>
        <Text style={styles.userName}>{user?.name || 'Utilisateur'}</Text>
        <Text style={styles.userEmail}>{user?.email || ''}</Text>
        <View style={styles.experienceBadge}>
          <Icon name="fitness" size={14} color={colors.primary[500]} />
          <Text style={styles.experienceText}>
            {EXPERIENCE_LABELS[user?.experience || ''] || 'Non défini'}
          </Text>
        </View>
      </View>

      {/* Stats Summary */}
      <View style={styles.statsRow}>
        <View style={styles.statItem}>
          <Text style={styles.statValue}>0</Text>
          <Text style={styles.statLabel}>Séances</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statValue}>0h</Text>
          <Text style={styles.statLabel}>Entraînement</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statValue}>0</Text>
          <Text style={styles.statLabel}>Plans</Text>
        </View>
      </View>

      {/* Menu Items */}
      <View style={styles.menuSection}>
        <Text style={styles.menuSectionTitle}>Entraînement</Text>

        <TouchableOpacity
          style={styles.menuItem}
          onPress={() => navigation.navigate('TrainingPlanCreator')}
        >
          <View style={styles.menuItemLeft}>
            <Icon name="calendar-outline" size={22} color={colors.primary[500]} />
            <Text style={styles.menuItemText}>Créer un plan d'entraînement</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.menuItem}
          onPress={() => navigation.navigate('Zones')}
        >
          <View style={styles.menuItemLeft}>
            <Icon name="heart-outline" size={22} color={colors.sports.running} />
            <Text style={styles.menuItemText}>Zones d'entraînement</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>

        <TouchableOpacity
          style={styles.menuItem}
          onPress={() => navigation.navigate('Equipment')}
        >
          <View style={styles.menuItemLeft}>
            <Icon name="bicycle-outline" size={22} color={colors.sports.cycling} />
            <Text style={styles.menuItemText}>Mon équipement</Text>
          </View>
          <View style={styles.menuItemRight}>
            {equipmentCount > 0 && (
              <View style={styles.countBadge}>
                <Text style={styles.countBadgeText}>{equipmentCount}</Text>
              </View>
            )}
            <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
          </View>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="fitness-outline" size={22} color={colors.primary[500]} />
            <Text style={styles.menuItemText}>Métriques sportives</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>
      </View>

      <View style={styles.menuSection}>
        <Text style={styles.menuSectionTitle}>Compte</Text>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="person-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>Modifier le profil</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>
      </View>

      <View style={styles.menuSection}>
        <Text style={styles.menuSectionTitle}>Appareils</Text>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="watch-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>Wahoo</Text>
          </View>
          <View style={styles.menuItemRight}>
            <Text style={styles.menuItemStatus}>Non connecté</Text>
            <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
          </View>
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="scale-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>Withings</Text>
          </View>
          <View style={styles.menuItemRight}>
            <Text style={styles.menuItemStatus}>Non connecté</Text>
            <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
          </View>
        </TouchableOpacity>
      </View>

      <View style={styles.menuSection}>
        <Text style={styles.menuSectionTitle}>Application</Text>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="notifications-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>Notifications</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="help-circle-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>Aide & Support</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>

        <TouchableOpacity style={styles.menuItem}>
          <View style={styles.menuItemLeft}>
            <Icon name="information-circle-outline" size={22} color={colors.secondary[600]} />
            <Text style={styles.menuItemText}>À propos</Text>
          </View>
          <Icon name="chevron-forward" size={20} color={colors.neutral.gray[400]} />
        </TouchableOpacity>
      </View>

      {/* Logout Button */}
      <TouchableOpacity style={styles.logoutButton} onPress={handleLogout}>
        <Icon name="log-out-outline" size={22} color={colors.status.error} />
        <Text style={styles.logoutText}>Déconnexion</Text>
      </TouchableOpacity>

      {/* Version */}
      <Text style={styles.version}>EdgeCoach v1.0.0</Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  content: {
    padding: spacing.container.horizontal,
    paddingBottom: spacing.xl,
  },
  profileHeader: {
    alignItems: 'center',
    marginBottom: spacing.lg,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: spacing.md,
  },
  avatarText: {
    ...typography.styles.h2,
    color: colors.neutral.white,
  },
  userName: {
    ...typography.styles.h3,
    color: colors.secondary[800],
  },
  userEmail: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  experienceBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.full,
    marginTop: spacing.md,
    gap: spacing.xs,
  },
  experienceText: {
    ...typography.styles.caption,
    color: colors.primary[600],
    fontWeight: '500',
  },
  statsRow: {
    flexDirection: 'row',
    backgroundColor: colors.neutral.white,
    borderRadius: spacing.borderRadius.lg,
    padding: spacing.lg,
    marginBottom: spacing.lg,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.05,
    shadowRadius: 8,
    elevation: 2,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    ...typography.styles.h3,
    color: colors.primary[500],
  },
  statLabel: {
    ...typography.styles.caption,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  statDivider: {
    width: 1,
    backgroundColor: colors.neutral.gray[200],
  },
  menuSection: {
    marginBottom: spacing.lg,
  },
  menuSectionTitle: {
    ...typography.styles.label,
    color: colors.neutral.gray[500],
    marginBottom: spacing.sm,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  menuItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.neutral.white,
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.lg,
    marginBottom: spacing.sm,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.md,
  },
  menuItemText: {
    ...typography.styles.body,
    color: colors.secondary[800],
  },
  menuItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  menuItemStatus: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
  },
  countBadge: {
    backgroundColor: colors.primary[500],
    minWidth: 22,
    height: 22,
    borderRadius: 11,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 6,
  },
  countBadgeText: {
    ...typography.styles.caption,
    fontSize: 11,
    color: colors.neutral.white,
    fontWeight: '700',
  },
  logoutButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.status.error + '10',
    paddingVertical: spacing.md,
    borderRadius: spacing.borderRadius.lg,
    marginTop: spacing.md,
    gap: spacing.sm,
  },
  logoutText: {
    ...typography.styles.button,
    color: colors.status.error,
  },
  version: {
    ...typography.styles.caption,
    color: colors.neutral.gray[400],
    textAlign: 'center',
    marginTop: spacing.lg,
  },
});

export default ProfileScreen;
