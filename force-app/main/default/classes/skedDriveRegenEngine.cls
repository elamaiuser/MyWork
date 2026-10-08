public interface skedDriveRegenEngine {
    // tokens: targetName -> targetValue (null for pseudo-tokens); mutates ctx in place
    void onDriveDataChanged(skedDriveRegenContext ctx, Map<String, Object> tokens);
}
