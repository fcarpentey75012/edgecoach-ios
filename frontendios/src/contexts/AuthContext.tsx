/**
 * AuthContext pour EdgeCoach iOS
 * Gestion de l'authentification avec AsyncStorage
 */

import React, {
  createContext,
  useContext,
  useState,
  useEffect,
  ReactNode,
} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { userService, User, RegisterData, LoginCredentials } from '../services';

// Types
interface AuthUser extends User {
  name: string;
  role: string;
}

interface AuthContextType {
  user: AuthUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginCredentials) => Promise<AuthResult>;
  register: (userData: RegisterData) => Promise<AuthResult>;
  logout: () => Promise<void>;
  updateUser: (updatedData: Partial<User>) => Promise<AuthResult>;
}

interface AuthResult {
  success: boolean;
  user?: AuthUser;
  error?: string;
}

// Clés de stockage
const STORAGE_KEYS = {
  AUTH_TOKEN: 'authToken',
  USER_DATA: 'userData',
};

// Context par défaut
const AuthContext = createContext<AuthContextType | undefined>(undefined);

// Hook useAuth
export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

// Provider Props
interface AuthProviderProps {
  children: ReactNode;
}

// AuthProvider Component
export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  // Initialisation - vérifier l'authentification existante
  useEffect(() => {
    const initAuth = async () => {
      try {
        const authToken = await AsyncStorage.getItem(STORAGE_KEYS.AUTH_TOKEN);
        const userData = await AsyncStorage.getItem(STORAGE_KEYS.USER_DATA);

        if (authToken && userData) {
          const parsedUser = JSON.parse(userData) as AuthUser;
          setUser(parsedUser);
          setIsAuthenticated(true);
        }
      } catch (error) {
        console.error('Error loading auth data:', error);
        // Nettoyer les données potentiellement corrompues
        await AsyncStorage.multiRemove([
          STORAGE_KEYS.AUTH_TOKEN,
          STORAGE_KEYS.USER_DATA,
        ]);
      } finally {
        setIsLoading(false);
      }
    };

    initAuth();
  }, []);

  // Adapter les données utilisateur API vers le format AuthUser
  const adaptUserData = (apiUser: User): AuthUser => {
    return {
      ...apiUser,
      name: `${apiUser.firstName} ${apiUser.lastName}`.trim(),
      role: 'user',
    };
  };

  // Générer un token temporaire (à remplacer par un vrai JWT du backend)
  const generateMockToken = (): string => {
    return `token_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  };

  // Connexion
  const login = async (credentials: LoginCredentials): Promise<AuthResult> => {
    try {
      setIsLoading(true);

      const result = await userService.login(credentials);

      if (result.success && result.user) {
        const adaptedUser = adaptUserData(result.user);
        const token = generateMockToken();

        // Sauvegarder dans AsyncStorage
        await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token);
        await AsyncStorage.setItem(
          STORAGE_KEYS.USER_DATA,
          JSON.stringify(adaptedUser)
        );

        setUser(adaptedUser);
        setIsAuthenticated(true);

        return { success: true, user: adaptedUser };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error: any) {
      console.error('Login error:', error);
      return { success: false, error: error.message || 'Erreur de connexion' };
    } finally {
      setIsLoading(false);
    }
  };

  // Inscription
  const register = async (userData: RegisterData): Promise<AuthResult> => {
    try {
      setIsLoading(true);

      const result = await userService.register(userData);

      if (result.success && result.user) {
        const adaptedUser = adaptUserData(result.user);
        const token = generateMockToken();

        // Sauvegarder dans AsyncStorage
        await AsyncStorage.setItem(STORAGE_KEYS.AUTH_TOKEN, token);
        await AsyncStorage.setItem(
          STORAGE_KEYS.USER_DATA,
          JSON.stringify(adaptedUser)
        );

        setUser(adaptedUser);
        setIsAuthenticated(true);

        return { success: true, user: adaptedUser };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error: any) {
      console.error('Registration error:', error);
      return { success: false, error: error.message || "Erreur d'inscription" };
    } finally {
      setIsLoading(false);
    }
  };

  // Déconnexion
  const logout = async (): Promise<void> => {
    try {
      await AsyncStorage.multiRemove([
        STORAGE_KEYS.AUTH_TOKEN,
        STORAGE_KEYS.USER_DATA,
      ]);
      setUser(null);
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Logout error:', error);
    }
  };

  // Mise à jour utilisateur
  const updateUser = async (updatedData: Partial<User>): Promise<AuthResult> => {
    try {
      if (!user?.id) {
        return { success: false, error: 'Utilisateur non connecté' };
      }

      const result = await userService.updateUser(user.id, updatedData);

      if (result.success && result.user) {
        const adaptedUser = adaptUserData(result.user);

        // Mettre à jour AsyncStorage
        await AsyncStorage.setItem(
          STORAGE_KEYS.USER_DATA,
          JSON.stringify(adaptedUser)
        );

        setUser(adaptedUser);

        return { success: true, user: adaptedUser };
      } else {
        return { success: false, error: result.error };
      }
    } catch (error: any) {
      console.error('Update user error:', error);
      return {
        success: false,
        error: error.message || 'Erreur de mise à jour',
      };
    }
  };

  // Valeur du context
  const value: AuthContextType = {
    user,
    isAuthenticated,
    isLoading,
    login,
    register,
    logout,
    updateUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export default AuthContext;
