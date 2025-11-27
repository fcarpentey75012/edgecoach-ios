/**
 * Écran d'inscription
 */

import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
  ActivityIndicator,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';
import Icon from 'react-native-vector-icons/Ionicons';
import { useAuth } from '../../contexts/AuthContext';
import { colors, spacing, typography } from '../../theme';
import { AuthStackParamList } from '../../navigation/types';

type RegisterScreenNavigationProp = NativeStackNavigationProp<AuthStackParamList, 'Register'>;

// Niveaux d'expérience disponibles
const EXPERIENCE_LEVELS = [
  { value: 'beginner', label: 'Débutant' },
  { value: 'intermediate', label: 'Intermédiaire' },
  { value: 'advanced', label: 'Avancé' },
  { value: 'expert', label: 'Expert' },
];

const RegisterScreen: React.FC = () => {
  const navigation = useNavigation<RegisterScreenNavigationProp>();
  const { register, isLoading } = useAuth();

  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [experienceLevel, setExperienceLevel] = useState('beginner');
  const [showPassword, setShowPassword] = useState(false);

  const handleRegister = async () => {
    // Validation
    if (!firstName.trim() || !lastName.trim() || !email.trim() || !password.trim()) {
      Alert.alert('Erreur', 'Veuillez remplir tous les champs');
      return;
    }

    if (password !== confirmPassword) {
      Alert.alert('Erreur', 'Les mots de passe ne correspondent pas');
      return;
    }

    if (password.length < 6) {
      Alert.alert('Erreur', 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }

    const result = await register({
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim(),
      password,
      experienceLevel,
    });

    if (!result.success) {
      Alert.alert('Erreur d\'inscription', result.error || 'Une erreur est survenue');
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <TouchableOpacity
            style={styles.backButton}
            onPress={() => navigation.goBack()}
          >
            <Icon name="arrow-back" size={24} color={colors.secondary[800]} />
          </TouchableOpacity>
          <Text style={styles.title}>Créer un compte</Text>
          <Text style={styles.subtitle}>Rejoignez EdgeCoach</Text>
        </View>

        {/* Formulaire */}
        <View style={styles.form}>
          {/* Nom et Prénom */}
          <View style={styles.row}>
            <View style={[styles.inputContainer, styles.halfInput]}>
              <TextInput
                style={styles.input}
                placeholder="Prénom"
                placeholderTextColor={colors.neutral.gray[400]}
                value={firstName}
                onChangeText={setFirstName}
              />
            </View>
            <View style={[styles.inputContainer, styles.halfInput]}>
              <TextInput
                style={styles.input}
                placeholder="Nom"
                placeholderTextColor={colors.neutral.gray[400]}
                value={lastName}
                onChangeText={setLastName}
              />
            </View>
          </View>

          {/* Email */}
          <View style={styles.inputContainer}>
            <Icon name="mail-outline" size={20} color={colors.neutral.gray[400]} style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder="Email"
              placeholderTextColor={colors.neutral.gray[400]}
              keyboardType="email-address"
              autoCapitalize="none"
              autoCorrect={false}
              value={email}
              onChangeText={setEmail}
            />
          </View>

          {/* Mot de passe */}
          <View style={styles.inputContainer}>
            <Icon name="lock-closed-outline" size={20} color={colors.neutral.gray[400]} style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder="Mot de passe"
              placeholderTextColor={colors.neutral.gray[400]}
              secureTextEntry={!showPassword}
              value={password}
              onChangeText={setPassword}
            />
            <TouchableOpacity
              onPress={() => setShowPassword(!showPassword)}
              style={styles.passwordToggle}
            >
              <Icon
                name={showPassword ? 'eye-off-outline' : 'eye-outline'}
                size={20}
                color={colors.neutral.gray[400]}
              />
            </TouchableOpacity>
          </View>

          {/* Confirmer mot de passe */}
          <View style={styles.inputContainer}>
            <Icon name="lock-closed-outline" size={20} color={colors.neutral.gray[400]} style={styles.inputIcon} />
            <TextInput
              style={styles.input}
              placeholder="Confirmer le mot de passe"
              placeholderTextColor={colors.neutral.gray[400]}
              secureTextEntry={!showPassword}
              value={confirmPassword}
              onChangeText={setConfirmPassword}
            />
          </View>

          {/* Niveau d'expérience */}
          <Text style={styles.label}>Niveau d'expérience</Text>
          <View style={styles.experienceContainer}>
            {EXPERIENCE_LEVELS.map((level) => (
              <TouchableOpacity
                key={level.value}
                style={[
                  styles.experienceButton,
                  experienceLevel === level.value && styles.experienceButtonActive,
                ]}
                onPress={() => setExperienceLevel(level.value)}
              >
                <Text
                  style={[
                    styles.experienceButtonText,
                    experienceLevel === level.value && styles.experienceButtonTextActive,
                  ]}
                >
                  {level.label}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <TouchableOpacity
            style={[styles.button, isLoading && styles.buttonDisabled]}
            onPress={handleRegister}
            disabled={isLoading}
          >
            {isLoading ? (
              <ActivityIndicator color={colors.neutral.white} />
            ) : (
              <Text style={styles.buttonText}>S'inscrire</Text>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={styles.linkButton}
            onPress={() => navigation.navigate('Login')}
          >
            <Text style={styles.linkText}>
              Déjà un compte ?{' '}
              <Text style={styles.linkTextBold}>Se connecter</Text>
            </Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.neutral.white,
  },
  scrollContent: {
    flexGrow: 1,
    padding: spacing.container.horizontal,
    paddingTop: spacing.xl,
  },
  header: {
    marginBottom: spacing.xl,
  },
  backButton: {
    marginBottom: spacing.md,
  },
  title: {
    ...typography.styles.h2,
    color: colors.secondary[800],
  },
  subtitle: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
    marginTop: spacing.xs,
  },
  form: {
    gap: spacing.md,
  },
  row: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  halfInput: {
    flex: 1,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.lg,
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
    paddingHorizontal: spacing.md,
  },
  inputIcon: {
    marginRight: spacing.sm,
  },
  input: {
    flex: 1,
    ...typography.styles.body,
    color: colors.secondary[800],
    paddingVertical: spacing.md,
  },
  passwordToggle: {
    padding: spacing.sm,
  },
  label: {
    ...typography.styles.label,
    color: colors.secondary[700],
    marginTop: spacing.sm,
  },
  experienceContainer: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
  },
  experienceButton: {
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.md,
    backgroundColor: colors.neutral.gray[100],
    borderWidth: 1,
    borderColor: colors.neutral.gray[200],
  },
  experienceButtonActive: {
    backgroundColor: colors.primary[50],
    borderColor: colors.primary[500],
  },
  experienceButtonText: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[600],
  },
  experienceButtonTextActive: {
    color: colors.primary[600],
    fontWeight: '600',
  },
  button: {
    backgroundColor: colors.primary[500],
    borderRadius: spacing.borderRadius.lg,
    paddingVertical: spacing.md,
    alignItems: 'center',
    marginTop: spacing.md,
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  buttonText: {
    ...typography.styles.button,
    color: colors.neutral.white,
  },
  linkButton: {
    alignItems: 'center',
    marginTop: spacing.md,
    marginBottom: spacing.xl,
  },
  linkText: {
    ...typography.styles.body,
    color: colors.neutral.gray[500],
  },
  linkTextBold: {
    color: colors.primary[500],
    fontWeight: '600',
  },
});

export default RegisterScreen;
