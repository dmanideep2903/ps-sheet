# Oracle Cloud Free Tier - DeskAttendance Setup Guide
## Fix: "Shape not compatible or not available" Error

---

## 🔧 SOLUTION: Try Different Availability Domains

Oracle Cloud Free Tier ARM instances are **highly sought after** and often run out of capacity. Here's how to fix:

### OPTION 1: Try All Availability Domains (FASTEST)

**In the "Create Instance" page:**

1. **Change Availability Domain:**
   - Current: AD-1 (Availability Domain 1)
   - Try: **AD-2** (Availability Domain 2)
   - Try: **AD-3** (Availability Domain 3)

2. **After changing AD, try the shape again:**
   - Shape: VM.Standard.A1.Flex
   - OCPUs: 4
   - Memory: 24 GB

3. **If still shows "not available":**
   - Try the next AD
   - Keep cycling through AD-1, AD-2, AD-3

**One of them will work!**

---

### OPTION 2: Use Smaller Shape First (WORKAROUND)

If NO availability domain works, temporarily use smaller specs:

**Temporary Specs:**
- Shape: VM.Standard.A1.Flex
- OCPUs: **2** (instead of 4)
- Memory: **12 GB** (instead of 24)

**You can resize later when capacity becomes available!**

---

### OPTION 3: Try Different Times (PEAK vs OFF-PEAK)

Oracle Cloud capacity varies by time:

**AVOID (Peak Hours in India):**
- ❌ 10 AM - 12 PM IST
- ❌ 2 PM - 5 PM IST
- ❌ 8 PM - 10 PM IST

**TRY (Off-Peak Hours):**
- ✅ **Early Morning: 5 AM - 8 AM IST** (BEST!)
- ✅ **Late Night: 11 PM - 2 AM IST**
- ✅ **Afternoon: 12 PM - 2 PM IST**

---

### OPTION 4: Keep Trying with Auto-Refresh Script

I can create a script that auto-retries instance creation. But first, try the manual methods above.

---

## ✅ RECOMMENDED STRATEGY (What You Should Do NOW)

### Step 1: Try All 3 Availability Domains

```
Current Page: Create Instance

1. Scroll to "Placement" section
2. Click "Availability Domain" dropdown
3. Select: AD-1
4. Scroll to "Shape" → VM.Standard.A1.Flex (4 OCPU, 24GB)
5. Does it say "not available"? → Try next AD

Repeat for:
- AD-2
- AD-3

SUCCESS when you see:
✅ "Always Free-eligible" badge (green)
✅ No error message
✅ Can enter 4 OCPUs and 24 GB RAM
```

---

### Step 2: If All ADs Show "Not Available"

**Option A: Use 2 OCPU / 12 GB temporarily**

This is still FREE and sufficient for 10 users:

```
Shape: VM.Standard.A1.Flex
OCPUs: 2 (still ARM64)
Memory: 12 GB

This handles:
✅ 10 DeskAttendance systems easily
✅ PostgreSQL database
✅ ASP.NET Core backend
✅ Still Always Free

Later: Resize to 4 OCPU / 24 GB when available
```

**Option B: Wait and try at off-peak hours**

```
Best time: Tomorrow 6 AM - 8 AM IST
Set alarm, create instance then
Higher success rate at off-peak hours
```

---

### Step 3: Alternative - Use x86 Shape (Less Desirable)

If ARM absolutely not available, use x86 temporarily:

**IMPORTANT: x86 has limits!**

```
Shape: VM.Standard.E2.1.Micro
Architecture: x86_64 (not ARM)
Specs: 1 OCPU, 1 GB RAM
Always Free: ✅ YES

Limitations:
⚠️ Only 1GB RAM (tight for 10 users)
⚠️ Only 1 OCPU (slower)
⚠️ Less storage (boot volume only)

Can work for testing, but:
→ Migrate to ARM when available
→ Or use Vultr/Linode (paid options)
```

---

## 🎯 MY RECOMMENDATION FOR YOU RIGHT NOW

### IMMEDIATE ACTION (Next 5 Minutes):

1. **Stay on "Create Instance" page**
2. **Try all 3 Availability Domains** (AD-1, AD-2, AD-3)
3. **If one works:** Continue with 4 OCPU / 24 GB ✅
4. **If none work:** Use 2 OCPU / 12 GB temporarily ✅

### Tomorrow Morning (6-8 AM):

1. **If you used 2 OCPU:** Try to resize to 4 OCPU / 24 GB
2. **If no instance yet:** Create with 4 OCPU / 24 GB at off-peak time

---

## 📝 CURRENT STATUS - WHAT TO DO NOW

**You're at: Create Instance page**
**Error: Shape not available in current AD**

**ACTION:**

```powershell
# Try this in PowerShell (check all regions for capacity)
# This checks which region has capacity
```

Actually, stay in the Oracle Cloud web console and:

### 🔄 TRY THIS RIGHT NOW:

1. **Change Availability Domain to AD-2**
   - Look for "Placement" section
   - Click dropdown next to "Availability domain"
   - Select **AD-2**

2. **Keep shape as:**
   - VM.Standard.A1.Flex
   - 4 OCPUs
   - 24 GB Memory

3. **Check if error disappears**

**Does AD-2 work?** (Yes/No)

---

## ⚡ QUICK TROUBLESHOOTING

**Q: All 3 ADs show "not available"**
A: Reduce to 2 OCPU / 12 GB (still free, still works!)

**Q: Can't find AD-2 or AD-3**
A: Your region might only have 1 AD. Try different region:
   - Mumbai → Hyderabad
   - Or use 2 OCPU / 12 GB

**Q: Should I wait or reduce specs?**
A: **Reduce to 2/12 NOW**, resize to 4/24 later when free

**Q: Will 2 OCPU / 12 GB work for 10 users?**
A: **YES!** Comfortable for 10 concurrent users

---

## 📊 CAPACITY COMPARISON

| Spec | Handles Users | Your Need | Status |
|------|---------------|-----------|--------|
| 4 OCPU / 24 GB | 50-100 users | 10 users | ✅ Overkill (but free!) |
| 2 OCPU / 12 GB | 20-30 users | 10 users | ✅ Perfect fit |
| 1 OCPU / 1 GB | 3-5 users | 10 users | ❌ Too small |

---

## 🎬 NEXT STEPS

**Tell me:**
1. Did AD-2 or AD-3 work?
2. OR should I help you create with 2 OCPU / 12 GB instead?

Once instance is created (any size), I'll guide you through:
- SSH key generation
- Server access
- PostgreSQL setup
- Backend deployment
- Connecting 10 desktop apps

**What's your current status? Which AD are you trying?**
