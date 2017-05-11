#!/bin/bash
. options.conf

patch_dir="$feeds_dir/base"
patch_file="ieee11s.patch"

cat > $patch_dir/$patch_file << EOF
From 6db7dcd74aaf23865ff19b515daf8c534414adaf Mon Sep 17 00:00:00 2001
From: Matthias Schiffer <mschiffer@universe-factory.net>
Date: Sat, 11 Mar 2017 06:15:18 +0100
Subject: [PATCH] mac80211: revert upstream change breaking AP+11s VIF
 combinations

Fixes FS#619.

Signed-off-by: Matthias Schiffer <mschiffer@universe-factory.net>
---
 ...0211-validate-new-interface-s-beacon-inte.patch | 48 ++++++++++++++++++++++
 .../522-mac80211_configure_antenna_gain.patch      |  4 +-
 2 files changed, 50 insertions(+), 2 deletions(-)
 create mode 100644 package/kernel/mac80211/patches/323-Revert-mac80211-validate-new-interface-s-beacon-inte.patch

diff --git a/package/kernel/mac80211/patches/323-Revert-mac80211-validate-new-interface-s-beacon-inte.patch b/package/kernel/mac80211/patches/323-Revert-mac80211-validate-new-interface-s-beacon-inte.patch
new file mode 100644
index 0000000..60d0e91
--- /dev/null
+++ b/package/kernel/mac80211/patches/323-Revert-mac80211-validate-new-interface-s-beacon-inte.patch
@@ -0,0 +1,48 @@
+From: Matthias Schiffer <mschiffer@universe-factory.net>
+Date: Sat, 11 Mar 2017 06:07:03 +0100
+Subject: [PATCH] Revert "mac80211: validate new interface's beacon intervals"
+
+This reverts commit ac668afe414b1d41366f92a33b4d32428335db54, as it
+prevents simultaneous operation of AP and mesh point VIFs.
+
+Signed-off-by: Matthias Schiffer <mschiffer@universe-factory.net>
+---
+
+--- a/net/mac80211/cfg.c
++++ b/net/mac80211/cfg.c
+@@ -864,8 +864,6 @@ static int ieee80211_start_ap(struct wip
+ 	}
+ 	sdata->needed_rx_chains = sdata->local->rx_chains;
+ 
+-	sdata->vif.bss_conf.beacon_int = params->beacon_interval;
+-
+ 	mutex_lock(&local->mtx);
+ 	err = ieee80211_vif_use_channel(sdata, &params->chandef,
+ 					IEEE80211_CHANCTX_SHARED);
+@@ -896,6 +894,7 @@ static int ieee80211_start_ap(struct wip
+ 					      vlan->vif.type);
+ 	}
+ 
++	sdata->vif.bss_conf.beacon_int = params->beacon_interval;
+ 	sdata->vif.bss_conf.dtim_period = params->dtim_period;
+ 	sdata->vif.bss_conf.enable_beacon = true;
+ 	sdata->vif.bss_conf.allow_p2p_go_ps = sdata->vif.p2p;
+--- a/net/mac80211/util.c
++++ b/net/mac80211/util.c
+@@ -3330,16 +3330,6 @@ int ieee80211_check_combinations(struct
+ 	if (WARN_ON(iftype >= NUM_NL80211_IFTYPES))
+ 		return -EINVAL;
+ 
+-	if (sdata->vif.type == NL80211_IFTYPE_AP ||
+-	    sdata->vif.type == NL80211_IFTYPE_MESH_POINT) {
+-		/*
+-		 * always passing this is harmless, since it'll be the
+-		 * same value that cfg80211 finds if it finds the same
+-		 * interface ... and that's always allowed
+-		 */
+-		params.new_beacon_int = sdata->vif.bss_conf.beacon_int;
+-	}
+-
+ 	/* Always allow software iftypes */
+ 	if (local->hw.wiphy->software_iftypes & BIT(iftype)) {
+ 		if (radar_detect)
diff --git a/package/kernel/mac80211/patches/522-mac80211_configure_antenna_gain.patch b/package/kernel/mac80211/patches/522-mac80211_configure_antenna_gain.patch
index 9a0f6f5..6856d69 100644
--- a/package/kernel/mac80211/patches/522-mac80211_configure_antenna_gain.patch
+++ b/package/kernel/mac80211/patches/522-mac80211_configure_antenna_gain.patch
@@ -57,7 +57,7 @@
  	__NL80211_ATTR_AFTER_LAST,
 --- a/net/mac80211/cfg.c
 +++ b/net/mac80211/cfg.c
-@@ -2396,6 +2396,19 @@ static int ieee80211_get_tx_power(struct
+@@ -2395,6 +2395,19 @@ static int ieee80211_get_tx_power(struct
  	return 0;
  }
  
@@ -77,7 +77,7 @@
  static int ieee80211_set_wds_peer(struct wiphy *wiphy, struct net_device *dev,
  				  const u8 *addr)
  {
-@@ -3627,6 +3640,7 @@ const struct cfg80211_ops mac80211_confi
+@@ -3626,6 +3639,7 @@ const struct cfg80211_ops mac80211_confi
  	.set_wiphy_params = ieee80211_set_wiphy_params,
  	.set_tx_power = ieee80211_set_tx_power,
  	.get_tx_power = ieee80211_get_tx_power,
-- 
2.1.4
EOF

[ ! -f $patch_dir/$patch_file ] && echo "-> Patch $patch_dir/$patch_file not found" && exit 1
(cd $patch_dir  && git apply $patch_file) && echo "Patches applied"

rm $patch_dir/$patch_file 2>/dev/null
