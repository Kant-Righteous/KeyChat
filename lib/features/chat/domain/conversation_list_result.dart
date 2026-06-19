enum ConversationListAction {
  selected,
  activeConversationDeleted,
}

class ConversationListResult {
  const ConversationListResult.selected(this.conversationId)
      : action = ConversationListAction.selected;

  const ConversationListResult.activeConversationDeleted()
      : action = ConversationListAction.activeConversationDeleted,
        conversationId = null;

  final ConversationListAction action;
  final String? conversationId;
}
