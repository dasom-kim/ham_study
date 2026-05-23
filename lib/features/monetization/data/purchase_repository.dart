abstract interface class PurchaseRepository {
  Future<bool> ownsMasterPass();
  Future<void> buyMasterPass();
  Stream<bool> watchMasterPass();
}
