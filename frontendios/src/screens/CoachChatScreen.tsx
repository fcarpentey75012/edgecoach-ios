/**
 * Écran Coach Chat - Chat avec l'IA
 * Connecté au backend EdgeCoach
 */

import React, { useState, useRef, useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from 'react-native';
import Icon from 'react-native-vector-icons/Ionicons';
import { useAuth } from '../contexts/AuthContext';
import { chatService, ChatMessage } from '../services';
import { coachService, SelectedCoach } from '../services/coachService';
import CoachSelector from '../components/CoachSelector';
import { sportColors } from '../data/coaches';
import { colors, spacing, typography } from '../theme';

interface Message {
  id: string;
  text: string;
  isUser: boolean;
  timestamp: Date;
  isLoading?: boolean;
}

const CoachChatScreen: React.FC = () => {
  const { user } = useAuth();
  const [selectedCoach, setSelectedCoach] = useState<SelectedCoach | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const flatListRef = useRef<FlatList>(null);

  // Scroll vers le bas à chaque mise à jour des messages
  const scrollToBottom = () => {
    setTimeout(() => {
      flatListRef.current?.scrollToEnd({ animated: true });
    }, 100);
  };

  // Scroll automatique quand les messages changent
  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  // Initialiser le coach et le message de bienvenue
  useEffect(() => {
    const initCoach = async () => {
      const coach = await coachService.initialize();
      setSelectedCoach(coach);
      setMessages([
        {
          id: '1',
          text: `Bonjour ! Je suis ${coach.name}, votre coach ${coach.speciality}. Comment puis-je vous aider aujourd'hui ?`,
          isUser: false,
          timestamp: new Date(),
        },
      ]);
    };
    initCoach();
  }, []);

  // Mettre à jour le message d'accueil quand le coach change
  const handleCoachChange = (coach: SelectedCoach) => {
    setSelectedCoach(coach);
    // Réinitialiser la conversation avec le nouveau coach
    setMessages([
      {
        id: Date.now().toString(),
        text: `Bonjour ! Je suis ${coach.name}, votre coach ${coach.speciality}. Comment puis-je vous aider aujourd'hui ?`,
        isUser: false,
        timestamp: new Date(),
      },
    ]);
  };

  // Convertir les messages locaux en format API
  const getConversationHistory = (): ChatMessage[] => {
    return messages
      .filter(msg => !msg.isLoading)
      .map(msg => ({
        content: msg.text,
        is_ai: !msg.isUser,
        timestamp: msg.timestamp.toISOString(),
      }));
  };

  const sendMessage = async () => {
    if (!inputText.trim() || isLoading || !user?.id) return;

    const userMessageText = inputText.trim();
    setInputText('');

    // Ajouter le message utilisateur
    const userMessage: Message = {
      id: Date.now().toString(),
      text: userMessageText,
      isUser: true,
      timestamp: new Date(),
    };

    // Ajouter un message "loading" pour l'IA
    const loadingMessage: Message = {
      id: (Date.now() + 1).toString(),
      text: '',
      isUser: false,
      timestamp: new Date(),
      isLoading: true,
    };

    setMessages(prev => [...prev, userMessage, loadingMessage]);
    setIsLoading(true);

    try {
      // Obtenir l'historique AVANT d'ajouter les nouveaux messages
      const history = getConversationHistory();

      let fullResponse = '';

      await chatService.sendMessage(
        user.id,
        userMessageText,
        history,
        {
          onChunk: (chunk: string) => {
            fullResponse += chunk;
            // Mettre à jour le message en temps réel (streaming)
            setMessages(prev =>
              prev.map(msg =>
                msg.isLoading
                  ? { ...msg, text: fullResponse, isLoading: false }
                  : msg
              )
            );
          },
          onComplete: (response: string) => {
            // S'assurer que le message final est bien affiché
            setMessages(prev =>
              prev.map(msg =>
                msg.isLoading
                  ? { ...msg, text: response || fullResponse, isLoading: false }
                  : msg
              )
            );
          },
          onError: (error: Error) => {
            console.error('Chat error:', error);
            // Remplacer le loading par un message d'erreur
            setMessages(prev =>
              prev.map(msg =>
                msg.isLoading
                  ? {
                      ...msg,
                      text: "Désolé, une erreur est survenue. Veuillez réessayer.",
                      isLoading: false,
                    }
                  : msg
              )
            );
          },
        }
      );
    } catch (error) {
      console.error('Send message error:', error);
      // Remplacer le loading par un message d'erreur
      setMessages(prev =>
        prev.map(msg =>
          msg.isLoading
            ? {
                ...msg,
                text: "Impossible de contacter le coach. Vérifiez votre connexion.",
                isLoading: false,
              }
            : msg
        )
      );
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickAction = (action: string) => {
    setInputText(action);
  };

  const coachColor = selectedCoach ? sportColors[selectedCoach.sport] : colors.primary[500];

  const renderMessage = ({ item }: { item: Message }) => (
    <View
      style={[
        styles.messageContainer,
        item.isUser ? styles.userMessage : styles.coachMessage,
      ]}
    >
      {!item.isUser && (
        <View style={[styles.coachAvatar, { backgroundColor: coachColor + '20' }]}>
          {selectedCoach ? (
            <Text style={[styles.coachAvatarText, { color: coachColor }]}>
              {selectedCoach.avatar}
            </Text>
          ) : (
            <Icon name="fitness" size={20} color={coachColor} />
          )}
        </View>
      )}
      <View
        style={[
          styles.messageBubble,
          item.isUser ? styles.userBubble : styles.coachBubble,
        ]}
      >
        {item.isLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="small" color={coachColor} />
            <Text style={styles.loadingText}>{selectedCoach?.name || 'Le coach'} réfléchit...</Text>
          </View>
        ) : (
          <Text
            style={[
              styles.messageText,
              item.isUser ? styles.userText : styles.coachText,
            ]}
          >
            {item.text}
          </Text>
        )}
      </View>
    </View>
  );

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
      keyboardVerticalOffset={90}
    >
      {/* Coach Selector */}
      <View style={styles.coachSelectorContainer}>
        <CoachSelector onCoachChange={handleCoachChange} />
      </View>

      {/* Messages List */}
      <FlatList
        ref={flatListRef}
        data={messages}
        renderItem={renderMessage}
        keyExtractor={item => item.id}
        contentContainerStyle={styles.messagesList}
        onContentSizeChange={() => flatListRef.current?.scrollToEnd()}
        onLayout={() => flatListRef.current?.scrollToEnd()}
      />

      {/* Quick Actions */}
      <View style={styles.quickActions}>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => handleQuickAction("Crée-moi un plan d'entraînement")}
        >
          <Icon name="calendar-outline" size={16} color={colors.primary[500]} />
          <Text style={styles.quickActionText}>Plan d'entraînement</Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={styles.quickAction}
          onPress={() => handleQuickAction("Analyse ma dernière séance")}
        >
          <Icon name="analytics-outline" size={16} color={colors.primary[500]} />
          <Text style={styles.quickActionText}>Analyser mes perfs</Text>
        </TouchableOpacity>
      </View>

      {/* Input Area */}
      <View style={styles.inputContainer}>
        <TextInput
          style={styles.input}
          placeholder="Posez votre question..."
          placeholderTextColor={colors.neutral.gray[400]}
          value={inputText}
          onChangeText={setInputText}
          multiline
          maxLength={500}
          editable={!isLoading}
        />
        <TouchableOpacity
          style={[
            styles.sendButton,
            (!inputText.trim() || isLoading) && styles.sendButtonDisabled,
          ]}
          onPress={sendMessage}
          disabled={!inputText.trim() || isLoading}
        >
          {isLoading ? (
            <ActivityIndicator size="small" color={colors.neutral.white} />
          ) : (
            <Icon
              name="send"
              size={20}
              color={inputText.trim() ? colors.neutral.white : colors.neutral.gray[400]}
            />
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.light.background,
  },
  coachSelectorContainer: {
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: spacing.xs,
  },
  messagesList: {
    padding: spacing.md,
    paddingBottom: spacing.lg,
  },
  messageContainer: {
    flexDirection: 'row',
    marginBottom: spacing.md,
    alignItems: 'flex-end',
  },
  userMessage: {
    justifyContent: 'flex-end',
  },
  coachMessage: {
    justifyContent: 'flex-start',
  },
  coachAvatar: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: colors.primary[50],
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: spacing.sm,
  },
  coachAvatarText: {
    fontSize: 12,
    fontWeight: '700',
  },
  messageBubble: {
    maxWidth: '75%',
    padding: spacing.md,
    borderRadius: spacing.borderRadius.lg,
  },
  userBubble: {
    backgroundColor: colors.primary[500],
    borderBottomRightRadius: spacing.borderRadius.sm,
  },
  coachBubble: {
    backgroundColor: colors.neutral.white,
    borderBottomLeftRadius: spacing.borderRadius.sm,
    shadowColor: colors.neutral.black,
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 1,
  },
  messageText: {
    ...typography.styles.body,
    lineHeight: 22,
  },
  userText: {
    color: colors.neutral.white,
  },
  coachText: {
    color: colors.secondary[800],
  },
  loadingContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing.sm,
  },
  loadingText: {
    ...typography.styles.bodySmall,
    color: colors.neutral.gray[500],
    fontStyle: 'italic',
  },
  quickActions: {
    flexDirection: 'row',
    paddingHorizontal: spacing.md,
    paddingBottom: spacing.sm,
    gap: spacing.sm,
  },
  quickAction: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.primary[50],
    paddingVertical: spacing.sm,
    paddingHorizontal: spacing.md,
    borderRadius: spacing.borderRadius.full,
    gap: spacing.xs,
  },
  quickActionText: {
    ...typography.styles.caption,
    color: colors.primary[600],
    fontWeight: '500',
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    padding: spacing.md,
    backgroundColor: colors.neutral.white,
    borderTopWidth: 1,
    borderTopColor: colors.neutral.gray[200],
  },
  input: {
    flex: 1,
    backgroundColor: colors.neutral.gray[50],
    borderRadius: spacing.borderRadius.lg,
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    ...typography.styles.body,
    color: colors.secondary[800],
    maxHeight: 100,
    marginRight: spacing.sm,
  },
  sendButton: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.primary[500],
    justifyContent: 'center',
    alignItems: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.neutral.gray[200],
  },
});

export default CoachChatScreen;
