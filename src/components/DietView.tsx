import React, { useState, useRef } from 'react';
import { Utensils, BookOpen, Clock, Info, ChevronRight, Bell, Check, Plus, Edit2, Trash2, Camera, Loader2 } from 'lucide-react';
import { Language, useTranslation } from '../lib/i18n';
import { cn } from '../lib/utils';
import { extractRecipeFromImage } from '../lib/gemini';

interface Recipe {
  id: string;
  titleEn: string;
  titleMy: string;
  time: string;
  ingredientsEn: string[];
  ingredientsMy: string[];
  instructionsEn: string[];
  instructionsMy: string[];
}

interface Meal {
  id: string;
  type: 'breakfast' | 'lunch' | 'dinner';
  titleEn: string;
  titleMy: string;
  time: string;
}

const initialRecipes: Recipe[] = [
  {
    id: '1',
    titleEn: 'Steamed Fish with Soy Sauce',
    titleMy: 'ပဲငံပြာရည်ဖြင့် ငါးပေါင်း',
    time: '20 mins',
    ingredientsEn: ['1 fresh fish (e.g., seabass)', '2 tbsp soy sauce', '1 tbsp ginger, sliced', '1 stalk spring onion'],
    ingredientsMy: ['ငါးလတ်လတ်ဆတ်ဆတ် ၁ ကောင်', 'ပဲငံပြာရည် စားပွဲတင်ဇွန်း ၂ ဇွန်း', 'ဂျင်းပြား ၁ စားပွဲတင်ဇွန်း', 'ကြက်သွန်မိတ် ၁ ပင်'],
    instructionsEn: ['Clean the fish and place on a steaming plate.', 'Top with ginger slices.', 'Steam for 10-12 minutes until cooked.', 'Pour soy sauce and garnish with spring onions.'],
    instructionsMy: ['ငါးကို သန့်စင်ပြီး ပေါင်းမည့်ပန်းကန်ပေါ်တင်ပါ။', 'ဂျင်းပြားများ အပေါ်မှတင်ပါ။', '၁၀-၁၂ မိနစ်ခန့် ကျက်သည်အထိပေါင်းပါ။', 'ပဲငံပြာရည်လောင်းထည့်ပြီး ကြက်သွန်မိတ်ဖြူးပါ။'],
  },
  {
    id: '2',
    titleEn: 'Chicken & Mushroom Porridge',
    titleMy: 'ကြက်သားနှင့် မှိုဆန်ပြုတ်',
    time: '45 mins',
    ingredientsEn: ['1/2 cup rice', '100g minced chicken', '3 shiitake mushrooms, sliced', '4 cups water or chicken broth'],
    ingredientsMy: ['ဆန် ခွက်တစ်ဝက်', 'ကြက်သားစဉ်းကော ၁၀၀ ဂရမ်', 'ရှီတာကီမှို ၃ ပွင့် (ပါးပါးလှီးပါ)', 'ရေ သို့မဟုတ် ကြက်ပြုတ်ရည် ၄ ခွက်'],
    instructionsEn: ['Wash rice and bring to boil with water/broth.', 'Simmer for 30 minutes until rice is soft.', 'Add chicken and mushrooms, cook for another 10 minutes.', 'Season lightly with salt.'],
    instructionsMy: ['ဆန်ကိုဆေးပြီး ရေ/ကြက်ပြုတ်ရည်ဖြင့် ဆူအောင်တည်ပါ။', 'ဆန်နူးသည်အထိ မိနစ် ၃၀ ခန့် မီးအေးအေးဖြင့်တည်ပါ။', 'ကြက်သားနှင့် မှိုထည့်ပြီး နောက်ထပ် ၁၀ မိနစ်ခန့် ချက်ပါ။', 'ဆားအနည်းငယ်ဖြင့် အရသာသွင်းပါ။'],
  },
  {
    id: '3',
    titleEn: 'Steamed Egg',
    titleMy: 'ကြက်ဥပေါင်း',
    time: '15 mins',
    ingredientsEn: ['2 eggs', '1 cup warm water', '1 tsp soy sauce', 'A pinch of salt'],
    ingredientsMy: ['ကြက်ဥ ၂ လုံး', 'ရေနွေး ၁ ခွက်', 'ပဲငံပြာရည် လက်ဖက်ရည်ဇွန်း ၁ ဇွန်း', 'ဆား အနည်းငယ်'],
    instructionsEn: ['Beat eggs gently with warm water and salt.', 'Strain the mixture into a bowl to remove bubbles.', 'Cover with a plate and steam on low heat for 10-12 minutes.', 'Drizzle with soy sauce before serving.'],
    instructionsMy: ['ကြက်ဥကို ရေနွေး၊ ဆားတို့ဖြင့် ဖြည်းညှင်းစွာ ခေါက်ပါ။', 'ပူဖောင်းများဖယ်ရှားရန် အရည်ကို စစ်ချပါ။', 'ပန်းကန်ပြားဖြင့်အုပ်ပြီး မီးအေးအေးဖြင့် ၁၀-၁၂ မိနစ်ခန့် ပေါင်းပါ။', 'မစားမီ ပဲငံပြာရည် အနည်းငယ်ဆမ်းပါ။'],
  }
];

const initialMeals: Meal[] = [
  { id: 'm1', type: 'breakfast', titleEn: 'Oatmeal with Soft Fruits', titleMy: 'အုတ်ဂျုံနှင့် သစ်သီးပျော့ပျော့', time: '08:30 AM' },
  { id: 'm2', type: 'lunch', titleEn: 'Chicken & Mushroom Porridge', titleMy: 'ကြက်သားနှင့် မှိုဆန်ပြုတ်', time: '12:30 PM' },
  { id: 'm3', type: 'dinner', titleEn: 'Steamed Fish with Rice', titleMy: 'ငါးပေါင်းနှင့် ထမင်း', time: '06:00 PM' },
];

export default function DietView({ lang }: { lang: Language }) {
  const t = useTranslation(lang);
  const [activeTab, setActiveTab] = useState<'plan' | 'recipes'>('plan');
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  const [meals, setMeals] = useState<Meal[]>(initialMeals);
  const [recipesList, setRecipesList] = useState<Recipe[]>(initialRecipes);

  const [isAddingMeal, setIsAddingMeal] = useState(false);
  const [editingMealId, setEditingMealId] = useState<string | null>(null);
  const [newMealTitle, setNewMealTitle] = useState('');
  const [newMealTime, setNewMealTime] = useState('');
  const [newMealType, setNewMealType] = useState<'breakfast' | 'lunch' | 'dinner'>('breakfast');

  const [isAddingRecipe, setIsAddingRecipe] = useState(false);
  const [editingRecipeId, setEditingRecipeId] = useState<string | null>(null);
  const [newRecipeTitle, setNewRecipeTitle] = useState('');
  const [newRecipeTime, setNewRecipeTime] = useState('');
  const [newRecipeIngredients, setNewRecipeIngredients] = useState('');
  const [newRecipeInstructions, setNewRecipeInstructions] = useState('');
  const [isScanning, setIsScanning] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleScanRecipe = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setIsScanning(true);
    try {
      const reader = new FileReader();
      reader.onloadend = async () => {
        const base64String = (reader.result as string).split(',')[1];
        try {
          const result = await extractRecipeFromImage(base64String, file.type, lang);
          
          setNewRecipeTitle(lang === 'en' ? result.titleEn : result.titleLocal);
          setNewRecipeTime(result.time);
          setNewRecipeIngredients((lang === 'en' ? result.ingredientsEn : result.ingredientsLocal).join('\n'));
          setNewRecipeInstructions((lang === 'en' ? result.instructionsEn : result.instructionsLocal).join('\n'));
          
          showToast('Recipe scanned successfully!');
        } catch (error) {
          showToast(t('scanError'));
        } finally {
          setIsScanning(false);
        }
      };
      reader.readAsDataURL(file);
    } catch (error) {
      setIsScanning(false);
      showToast(t('scanError'));
    }
  };

  const showToast = (msg: string) => {
    setToast(msg);
    setTimeout(() => setToast(null), 3000);
  };

  const saveMeal = () => {
    if (!newMealTitle || !newMealTime) return;
    if (editingMealId) {
      setMeals(meals.map(m => m.id === editingMealId ? { ...m, titleEn: newMealTitle, titleMy: newMealTitle, time: newMealTime, type: newMealType } : m));
    } else {
      setMeals([...meals, { id: Date.now().toString(), titleEn: newMealTitle, titleMy: newMealTitle, time: newMealTime, type: newMealType }].sort((a, b) => a.time.localeCompare(b.time)));
    }
    cancelMealEdit();
  };

  const editMeal = (meal: Meal) => {
    setEditingMealId(meal.id);
    setNewMealTitle(meal.titleEn);
    setNewMealTime(meal.time);
    setNewMealType(meal.type);
    setIsAddingMeal(true);
  };

  const deleteMeal = (id: string) => {
    setMeals(meals.filter(m => m.id !== id));
  };

  const cancelMealEdit = () => {
    setIsAddingMeal(false);
    setEditingMealId(null);
    setNewMealTitle('');
    setNewMealTime('');
    setNewMealType('breakfast');
  };

  const saveRecipe = () => {
    if (!newRecipeTitle || !newRecipeTime) return;
    const ingredients = newRecipeIngredients.split('\n').filter(i => i.trim());
    const instructions = newRecipeInstructions.split('\n').filter(i => i.trim());

    if (editingRecipeId) {
      setRecipesList(recipesList.map(r => r.id === editingRecipeId ? { 
        ...r, titleEn: newRecipeTitle, titleMy: newRecipeTitle, time: newRecipeTime, 
        ingredientsEn: ingredients, ingredientsMy: ingredients, 
        instructionsEn: instructions, instructionsMy: instructions 
      } : r));
    } else {
      setRecipesList([...recipesList, { 
        id: Date.now().toString(), titleEn: newRecipeTitle, titleMy: newRecipeTitle, time: newRecipeTime, 
        ingredientsEn: ingredients, ingredientsMy: ingredients, 
        instructionsEn: instructions, instructionsMy: instructions 
      }]);
    }
    cancelRecipeEdit();
  };

  const editRecipe = (recipe: Recipe) => {
    setEditingRecipeId(recipe.id);
    setNewRecipeTitle(recipe.titleEn);
    setNewRecipeTime(recipe.time);
    setNewRecipeIngredients(recipe.ingredientsEn.join('\n'));
    setNewRecipeInstructions(recipe.instructionsEn.join('\n'));
    setIsAddingRecipe(true);
  };

  const deleteRecipe = (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setRecipesList(recipesList.filter(r => r.id !== id));
  };

  const cancelRecipeEdit = () => {
    setIsAddingRecipe(false);
    setEditingRecipeId(null);
    setNewRecipeTitle('');
    setNewRecipeTime('');
    setNewRecipeIngredients('');
    setNewRecipeInstructions('');
  };

  if (selectedRecipe) {
    return (
      <div className="p-4 max-w-md mx-auto pb-24">
        <button 
          onClick={() => setSelectedRecipe(null)}
          className="text-indigo-600 font-semibold mb-6 flex items-center bg-white/50 backdrop-blur-md px-3 py-1.5 rounded-full w-fit hover:bg-white transition-colors"
        >
          <ChevronRight className="w-5 h-5 rotate-180 mr-1" />
          Back
        </button>
        
        <h2 className="text-3xl font-bold tracking-tight text-slate-800 mb-2">
          {lang === 'en' ? selectedRecipe.titleEn : selectedRecipe.titleMy}
        </h2>
        <p className="text-slate-500 mb-6 flex items-center gap-1.5">
          <Clock className="w-4 h-4" /> {selectedRecipe.time}
        </p>

        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white mb-6">
          <h3 className="font-bold text-lg text-slate-800 mb-3 flex items-center gap-2">
            <Info className="w-5 h-5 text-indigo-500" />
            {t('ingredients')}
          </h3>
          <ul className="space-y-2">
            {(lang === 'en' ? selectedRecipe.ingredientsEn : selectedRecipe.ingredientsMy).map((ing, idx) => (
              <li key={idx} className="flex items-start gap-2 text-slate-700">
                <span className="w-1.5 h-1.5 rounded-full bg-indigo-400 mt-2 shrink-0" />
                <span>{ing}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white">
          <h3 className="font-bold text-lg text-slate-800 mb-3 flex items-center gap-2">
            <Utensils className="w-5 h-5 text-indigo-500" />
            {t('instructions')}
          </h3>
          <ol className="space-y-4">
            {(lang === 'en' ? selectedRecipe.instructionsEn : selectedRecipe.instructionsMy).map((inst, idx) => (
              <li key={idx} className="flex gap-3 text-slate-700">
                <span className="font-bold text-indigo-300 shrink-0">{idx + 1}.</span>
                <span>{inst}</span>
              </li>
            ))}
          </ol>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-md mx-auto pb-24 relative">
      {toast && (
        <div className="fixed top-20 left-1/2 -translate-x-1/2 bg-slate-800/90 backdrop-blur-md text-white px-5 py-3 rounded-full shadow-xl z-50 flex items-center gap-3 animate-in fade-in slide-in-from-top-4">
          <Check className="w-5 h-5 text-emerald-400" />
          <span className="text-sm font-semibold">{toast}</span>
        </div>
      )}

      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold tracking-tight text-slate-800">{t('diet')}</h2>
        <div className="flex items-center gap-2">
          <button onClick={() => showToast(t('notificationSent'))} className="p-2.5 bg-white/60 backdrop-blur-md border border-white shadow-sm rounded-full text-indigo-600 hover:bg-white transition-all active:scale-95">
            <Bell className="w-5 h-5" />
          </button>
          <button
            onClick={() => {
              if (activeTab === 'plan') {
                cancelMealEdit();
                setIsAddingMeal(true);
              } else {
                cancelRecipeEdit();
                setIsAddingRecipe(true);
              }
            }}
            className="p-2.5 bg-gradient-to-r from-indigo-500 to-purple-500 text-white rounded-full shadow-lg shadow-indigo-200 hover:shadow-xl hover:scale-105 transition-all active:scale-95"
          >
            <Plus className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Tab Switcher */}
      <div className="bg-white/60 backdrop-blur-xl p-1.5 rounded-2xl shadow-sm border border-white flex w-full mb-8 relative">
        <div 
          className={cn(
            "absolute inset-y-1.5 w-[calc(50%-6px)] bg-white rounded-xl shadow-sm transition-all duration-300 ease-out",
            activeTab === 'plan' ? "left-1.5" : "left-[calc(50%+4px)]"
          )}
        />
        <button
          onClick={() => setActiveTab('plan')}
          className={cn(
            "flex-1 py-3 text-sm font-semibold rounded-xl z-10 transition-colors flex items-center justify-center gap-2",
            activeTab === 'plan' ? "text-indigo-600" : "text-slate-500 hover:text-slate-700"
          )}
        >
          <Utensils className="w-4 h-4" />
          {t('mealPlan')}
        </button>
        <button
          onClick={() => setActiveTab('recipes')}
          className={cn(
            "flex-1 py-3 text-sm font-semibold rounded-xl z-10 transition-colors flex items-center justify-center gap-2",
            activeTab === 'recipes' ? "text-indigo-600" : "text-slate-500 hover:text-slate-700"
          )}
        >
          <BookOpen className="w-4 h-4" />
          {t('recipes')}
        </button>
      </div>

      {activeTab === 'plan' ? (
        <div className="space-y-4">
          {isAddingMeal && (
            <div className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white mb-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t("mealName")}</label>
                <input
                  type="text"
                  value={newMealTitle}
                  onChange={(e) => setNewMealTitle(e.target.value)}
                  className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  placeholder="e.g. Oatmeal"
                />
              </div>
              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t("time")}</label>
                  <input
                    type="time"
                    value={newMealTime}
                    onChange={(e) => setNewMealTime(e.target.value)}
                    className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t("type")}</label>
                  <select
                    value={newMealType}
                    onChange={(e) => setNewMealType(e.target.value as any)}
                    className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  >
                    <option value="breakfast">{t('breakfast')}</option>
                    <option value="lunch">{t('lunch')}</option>
                    <option value="dinner">{t('dinner')}</option>
                  </select>
                </div>
              </div>
              <div className="flex gap-2 pt-2">
                <button onClick={saveMeal} className="flex-1 bg-gradient-to-r from-indigo-500 to-purple-500 text-white py-3 rounded-xl font-semibold shadow-md shadow-indigo-200 hover:shadow-lg transition-all active:scale-95">
                  {t("save")}
                </button>
                <button onClick={cancelMealEdit} className="flex-1 bg-slate-100/80 text-slate-700 py-3 rounded-xl font-semibold hover:bg-slate-200 transition-all active:scale-95">
                  {t("cancel")}
                </button>
              </div>
            </div>
          )}

          {meals.map((meal) => (
            <div key={meal.id} className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white flex items-start gap-4 transition-transform">
              <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-indigo-50 to-purple-50 flex items-center justify-center shrink-0 text-indigo-600 font-bold text-sm shadow-inner border border-white">
                {meal.time.split(' ')[0]}
              </div>
              <div className="flex-1">
                <span className="text-xs font-bold text-indigo-500 uppercase tracking-wider mb-1 block">
                  {t(meal.type)}
                </span>
                <p className="font-medium text-slate-900 text-lg leading-tight mb-1">
                  {lang === 'en' ? meal.titleEn : meal.titleMy}
                </p>
                {lang === 'en' && meal.titleMy && (
                  <p className="text-sm text-slate-500">{meal.titleMy}</p>
                )}
                {lang !== 'en' && meal.titleEn && (
                  <p className="text-sm text-slate-500">{meal.titleEn}</p>
                )}
              </div>
              <div className="flex flex-col gap-2 shrink-0">
                <button onClick={() => editMeal(meal)} className="p-2 text-slate-400 hover:text-indigo-600 bg-white/50 rounded-full transition-colors hover:bg-indigo-50">
                  <Edit2 className="w-4 h-4" />
                </button>
                <button onClick={() => deleteMeal(meal.id)} className="p-2 text-slate-400 hover:text-rose-600 bg-white/50 rounded-full transition-colors hover:bg-rose-50">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="space-y-3">
          {isAddingRecipe && (
            <div className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white mb-6 space-y-4">
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-bold text-slate-800">{t('addRecipe')}</h3>
                <button
                  onClick={() => fileInputRef.current?.click()}
                  disabled={isScanning}
                  className="flex items-center gap-2 px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-full text-sm font-semibold hover:bg-indigo-100 transition-colors disabled:opacity-50"
                >
                  {isScanning ? <Loader2 className="w-4 h-4 animate-spin" /> : <Camera className="w-4 h-4" />}
                  {isScanning ? t('scanning') : t('scanRecipe')}
                </button>
                <input
                  type="file"
                  accept="image/*"
                  ref={fileInputRef}
                  onChange={handleScanRecipe}
                  className="hidden"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t("recipeName")}</label>
                <input
                  type="text"
                  value={newRecipeTitle}
                  onChange={(e) => setNewRecipeTitle(e.target.value)}
                  className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  placeholder="e.g. Chicken Soup"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t("time")}</label>
                <input
                  type="text"
                  value={newRecipeTime}
                  onChange={(e) => setNewRecipeTime(e.target.value)}
                  className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all"
                  placeholder="e.g. 30 mins"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t("ingredients")} (one per line)</label>
                <textarea
                  value={newRecipeIngredients}
                  onChange={(e) => setNewRecipeIngredients(e.target.value)}
                  className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all min-h-[100px]"
                  placeholder="1 cup rice&#10;2 cups water"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t("instructions")} (one per line)</label>
                <textarea
                  value={newRecipeInstructions}
                  onChange={(e) => setNewRecipeInstructions(e.target.value)}
                  className="w-full px-4 py-3 bg-white/50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all min-h-[100px]"
                  placeholder="Wash rice&#10;Boil water"
                />
              </div>
              <div className="flex gap-2 pt-2">
                <button onClick={saveRecipe} className="flex-1 bg-gradient-to-r from-indigo-500 to-purple-500 text-white py-3 rounded-xl font-semibold shadow-md shadow-indigo-200 hover:shadow-lg transition-all active:scale-95">
                  {t("save")}
                </button>
                <button onClick={cancelRecipeEdit} className="flex-1 bg-slate-100/80 text-slate-700 py-3 rounded-xl font-semibold hover:bg-slate-200 transition-all active:scale-95">
                  {t("cancel")}
                </button>
              </div>
            </div>
          )}

          {recipesList.map((recipe) => (
            <div 
              key={recipe.id}
              onClick={() => setSelectedRecipe(recipe)}
              className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white flex items-center justify-between cursor-pointer hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] hover:scale-[1.02] transition-all"
            >
              <div className="flex-1 pr-4">
                <p className="font-medium text-slate-900 text-lg leading-tight mb-1">
                  {lang === 'en' ? recipe.titleEn : recipe.titleMy}
                </p>
                {lang === 'en' && recipe.titleMy && (
                  <p className="text-sm text-slate-500 mb-2">{recipe.titleMy}</p>
                )}
                {lang !== 'en' && recipe.titleEn && (
                  <p className="text-sm text-slate-500 mb-2">{recipe.titleEn}</p>
                )}
                <div className="flex items-center gap-1.5 text-xs text-slate-600 font-semibold bg-slate-100/80 backdrop-blur-sm w-fit px-2.5 py-1 rounded-lg">
                  <Clock className="w-3.5 h-3.5" />
                  {recipe.time}
                </div>
              </div>
              <div className="flex flex-col gap-2 shrink-0 mr-2">
                <button onClick={(e) => { e.stopPropagation(); editRecipe(recipe); }} className="p-2 text-slate-400 hover:text-indigo-600 bg-white/50 rounded-full transition-colors hover:bg-indigo-50">
                  <Edit2 className="w-4 h-4" />
                </button>
                <button onClick={(e) => deleteRecipe(recipe.id, e)} className="p-2 text-slate-400 hover:text-rose-600 bg-white/50 rounded-full transition-colors hover:bg-rose-50">
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
              <ChevronRight className="w-5 h-5 text-slate-400 shrink-0" />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
