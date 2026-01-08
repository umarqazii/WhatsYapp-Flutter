String getChatId(String userA, String userB) {
  // Sort emails to ensure consistent ID generation regardless of who starts the chat
  if (userA.compareTo(userB) < 0) {
    return '${userA}_$userB';
  } else {
    return '${userB}_$userA';
  }
}