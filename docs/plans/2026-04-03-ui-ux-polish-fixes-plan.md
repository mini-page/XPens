# UI/UX Polish and Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix broken animations, improve layout symmetry, and implement mobile-friendly navigation.

**Architecture:** 
- Standardize animation class names across CSS and HTML.
- Adjust Tailwind grid columns for optimal card distribution.
- Use a checkbox-hack or simple JS toggle for the mobile navigation drawer.
- Unify section backgrounds with consistent gradients.

**Tech Stack:** HTML5, Tailwind CSS, FontAwesome, JavaScript.

---

### Task 1: Fix Broken Animations & Hero Layout

**Files:**
- Modify: `index.html` (Hero section and CSS definitions)

**Step 1: Unify animation class names**
Update `animate-fade-in-up` to `animate-fadeInUp` in the Hero section (lines 493-511).

**Step 2: Add mobile button stacking**
Add `w-full sm:w-auto` to the "Get XPensa" and "View Source" buttons in the Hero section for better mobile flow.

**Step 3: Commit**
```bash
git add index.html
git commit -m "fix: resolve broken hero animations and improve mobile button layout"
```

### Task 2: Standardize Section Gradients & Accessibility

**Files:**
- Modify: `index.html` (Stats and Categories sections)

**Step 1: Update Stats Section background**
Change `bg-gradient-to-r from-blue-500 to-blue-600` in the Stats section (line 858) to `from-blue-600 to-blue-500` to match the CTA banner style.

**Step 2: Add aria-hidden to decorative icons**
Ensure all icons in the "Stats" and "Categories Showcase" sections have `aria-hidden="true"`.

**Step 3: Commit**
```bash
git add index.html
git commit -m "style: unify section gradients and improve accessibility for decorative icons"
```

### Task 3: Optimize Input Methods Grid

**Files:**
- Modify: `index.html` (Multiple Input Methods section)

**Step 1: Fix grid columns**
Change `grid md:grid-cols-5 gap-6` to `grid md:grid-cols-3 lg:grid-cols-6 gap-6` in the "Multiple Input Methods" section (line 887) to better accommodate 6 cards.

**Step 2: Commit**
```bash
git add index.html
git commit -m "style: optimize input methods grid layout for better symmetry"
```

### Task 4: Implement Mobile Navigation

**Files:**
- Modify: `index.html` (Navigation section and Script)

**Step 1: Add Hamburger Button**
Add a menu button (bars icon) that is visible only on mobile (`md:hidden`).

**Step 2: Add Mobile Menu Drawer**
Add a hidden div for the mobile menu that toggles when the hamburger is clicked.

**Step 3: Add Toggle Script**
Add a simple JS function to toggle the mobile menu visibility.

**Step 4: Commit**
```bash
git add index.html
git commit -m "feat: implement responsive mobile navigation menu"
```

### Task 5: Refactor Mockup Features to Mini-Cards

**Files:**
- Modify: `index.html` (Mockup section side features)

**Step 1: Redesign Side Features**
Convert the 7 features around the phone mockup (Lightning Fast, Beautiful UI, etc.) into "Mini Cards" using the same design language as the main feature grid (rounded-2xl, vibrant icon background), but smaller (`p-4` instead of `p-6`).

**Step 2: Commit**
```bash
git add index.html
git commit -m "style: unify side-features with the main design system"
```
