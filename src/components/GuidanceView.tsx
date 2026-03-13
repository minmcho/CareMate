import { useState } from 'react';
import { ChevronRight, CheckCircle2, PlayCircle, Loader2 } from 'lucide-react';
import { Language, useTranslation } from '../lib/i18n';

type LocalizedString = Partial<Record<Language, string>> & { en: string };
type LocalizedStringArray = Partial<Record<Language, string[]>> & { en: string[] };

interface Module {
  id: string;
  category: 'theory' | 'practical' | 'skills';
  title: LocalizedString;
  videoUrl: string;
  items: LocalizedStringArray;
}

const modules: Module[] = [
  {
    id: 'theory',
    category: 'theory',
    title: {
      en: 'Theory Modules',
      my: 'သီအိုရီ သင်ခန်းစာများ',
      th: 'โมดูลทฤษฎี',
      ar: 'الوحدات النظرية'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    items: {
      en: [
        'Personal Hygiene of Care Recipients',
        'Nutrition',
        'Bladder Care',
        'Basic Infection Control',
        'Wound Care',
        'Bed Mobility and Prevention of Pressure Ulcers/Bed Sores',
        'Home Safety and Fall Prevention',
        'Medication Management',
        'Communicating with the Care Recipient',
        'Medical Emergencies'
      ],
      my: [
        'ပြုစုစောင့်ရှောက်ခံရသူများ၏ တစ်ကိုယ်ရေ သန့်ရှင်းရေး',
        'အာဟာရ',
        'ဆီးအိမ် စောင့်ရှောက်မှု',
        'အခြေခံ ကူးစက်ရောဂါ ထိန်းချုပ်ရေး',
        'ဒဏ်ရာ စောင့်ရှောက်မှု',
        'အိပ်ရာပေါ် ရွေ့လျားမှုနှင့် အိပ်ရာနာ/ဖိအားကြောင့်ဖြစ်သော အနာများ ကာကွယ်ခြင်း',
        'အိမ်တွင်း ဘေးကင်းရေးနှင့် ချော်လဲမှု ကာကွယ်ရေး',
        'ဆေးဝါး စီမံခန့်ခွဲမှု',
        'ပြုစုစောင့်ရှောက်ခံရသူနှင့် ဆက်သွယ်ခြင်း',
        'ဆေးဘက်ဆိုင်ရာ အရေးပေါ်အခြေအနေများ'
      ],
      th: [
        'สุขอนามัยส่วนบุคคลของผู้รับการดูแล',
        'โภชนาการ',
        'การดูแลกระเพาะปัสสาวะ',
        'การควบคุมการติดเชื้อขั้นพื้นฐาน',
        'การดูแลแผล',
        'การเคลื่อนไหวบนเตียงและการป้องกันแผลกดทับ',
        'ความปลอดภัยในบ้านและการป้องกันการหกล้ม',
        'การจัดการยา',
        'การสื่อสารกับผู้รับการดูแล',
        'เหตุฉุกเฉินทางการแพทย์'
      ],
      ar: [
        'النظافة الشخصية لمتلقي الرعاية',
        'التغذية',
        'العناية بالمثانة',
        'مكافحة العدوى الأساسية',
        'العناية بالجروح',
        'الحركة في السرير والوقاية من تقرحات الفراش',
        'السلامة المنزلية والوقاية من السقوط',
        'إدارة الأدوية',
        'التواصل مع متلقي الرعاية',
        'حالات الطوارئ الطبية'
      ]
    }
  },
  {
    id: 'practical',
    category: 'practical',
    title: {
      en: 'Practical Modules',
      my: 'လက်တွေ့ သင်ခန်းစာများ',
      th: 'โมดูลปฏิบัติ',
      ar: 'الوحدات العملية'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    items: {
      en: [
        'Personal Hygiene of Care Recipient',
        'Safe Transfer Technique',
        'Mobility Aids and Their Uses'
      ],
      my: [
        'ပြုစုစောင့်ရှောက်ခံရသူ၏ တစ်ကိုယ်ရေ သန့်ရှင်းရေး',
        'ဘေးကင်းသော ရွှေ့ပြောင်းခြင်း နည်းစနစ်',
        'ရွေ့လျားသွားလာရေး အထောက်အကူပြု ပစ္စည်းများနှင့် ၎င်းတို့၏ အသုံးပြုမှုများ'
      ],
      th: [
        'สุขอนามัยส่วนบุคคลของผู้รับการดูแล',
        'เทคนิคการเคลื่อนย้ายอย่างปลอดภัย',
        'อุปกรณ์ช่วยเดินและการใช้งาน'
      ],
      ar: [
        'النظافة الشخصية لمتلقي الرعاية',
        'تقنية النقل الآمن',
        'مساعدات الحركة واستخداماتها'
      ]
    }
  },
  {
    id: 'hygiene-partial',
    category: 'skills',
    title: {
      en: 'Basic Hygiene – Partially Dependent',
      my: 'အခြေခံ တစ်ကိုယ်ရေသန့်ရှင်းရေး - တစ်စိတ်တစ်ပိုင်း မှီခိုသူ',
      th: 'สุขอนามัยพื้นฐาน – พึ่งพาบางส่วน',
      ar: 'النظافة الأساسية - معتمد جزئياً'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    items: {
      en: [
        'Assist them to shower in the bathroom',
        'Assist to change their clothes',
        'Assist them in grooming/brushing their teeth',
        'Assist them in changing the bed linen',
        'Make them feel comfortable',
        'Look out for any skin condition and seek medical attention',
        'Help them dry their body thoroughly',
        'Give them fresh set of clothes to wear'
      ],
      my: [
        'ရေချိုးခန်းထဲတွင် ရေချိုးရန် ကူညီပါ',
        'အဝတ်အစားလဲရန် ကူညီပါ',
        'အလှပြင်ရန်/သွားတိုက်ရန် ကူညီပါ',
        'အိပ်ရာခင်းလဲရန် ကူညီပါ',
        'သက်တောင့်သက်သာရှိစေရန် လုပ်ဆောင်ပေးပါ',
        'အရေပြား အခြေအနေကို စစ်ဆေးပြီး လိုအပ်ပါက ဆေးဘက်ဆိုင်ရာ အကူအညီရယူပါ',
        'ခန္ဓာကိုယ်ကို သေချာစွာ ခြောက်သွေ့အောင် ကူညီပါ',
        'သန့်ရှင်းသော အဝတ်အစားများ ဝတ်ဆင်ပေးပါ'
      ],
      th: [
        'ช่วยพวกเขาอาบน้ำในห้องน้ำ',
        'ช่วยเปลี่ยนเสื้อผ้า',
        'ช่วยดูแลความสะอาด/แปรงฟัน',
        'ช่วยเปลี่ยนผ้าปูที่นอน',
        'ทำให้พวกเขารู้สึกสบาย',
        'สังเกตสภาพผิวหนังและไปพบแพทย์หากจำเป็น',
        'ช่วยเช็ดตัวให้แห้งสนิท',
        'ให้เสื้อผ้าชุดใหม่เพื่อสวมใส่'
      ],
      ar: [
        'مساعدتهم على الاستحمام في الحمام',
        'المساعدة في تغيير ملابسهم',
        'مساعدتهم في العناية بمظهرهم/تنظيف أسنانهم',
        'مساعدتهم في تغيير بياضات السرير',
        'جعلهم يشعرون بالراحة',
        'الانتباه لأي حالة جلدية وطلب العناية الطبية',
        'مساعدتهم على تجفيف أجسامهم تماماً',
        'إعطائهم مجموعة ملابس نظيفة لارتدائها'
      ]
    }
  },
  {
    id: 'toilet-bath',
    category: 'skills',
    title: {
      en: 'Toilet Bath (Partially Dependent)',
      my: 'ရေချိုးခန်းသုံးခြင်း (တစ်စိတ်တစ်ပိုင်း မှီခိုသူ)',
      th: 'การอาบน้ำในห้องน้ำ (พึ่งพาบางส่วน)',
      ar: 'الاستحمام في المرحاض (معتمد جزئياً)'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    items: {
      en: [
        'Encourage them to clear bowels before showering',
        'Encourage self-help as much as possible',
        'Assist them only in the areas they cannot reach',
        'Pay attention to: neck, behind the ears, armpit, genitalia, buttocks, feet, any skin folds (for heavier persons)'
      ],
      my: [
        'ရေမချိုးမီ ဝမ်းသွားရန် တိုက်တွန်းပါ',
        'တတ်နိုင်သမျှ ကိုယ်တိုင်လုပ်ဆောင်ရန် တိုက်တွန်းပါ',
        'သူတို့ မမီသော နေရာများကိုသာ ကူညီပါ',
        'ဂရုစိုက်ရမည့် နေရာများ - လည်ပင်း၊ နားနောက်၊ ဂျိုင်း၊ လိင်အင်္ဂါ၊ တင်ပါး၊ ခြေထောက်၊ အရေပြား ခေါက်နေသော နေရာများ (ဝသောသူများအတွက်)'
      ],
      th: [
        'กระตุ้นให้ขับถ่ายก่อนอาบน้ำ',
        'ส่งเสริมให้ช่วยเหลือตัวเองมากที่สุด',
        'ช่วยเหลือเฉพาะบริเวณที่พวกเขาเอื้อมไม่ถึง',
        'ให้ความสนใจกับ: คอ, หลังหู, รักแร้, อวัยวะเพศ, ก้น, เท้า, รอยพับของผิวหนัง (สำหรับคนอ้วน)'
      ],
      ar: [
        'تشجيعهم على إفراغ الأمعاء قبل الاستحمام',
        'تشجيع المساعدة الذاتية قدر الإمكان',
        'مساعدتهم فقط في المناطق التي لا يمكنهم الوصول إليها',
        'الانتباه إلى: الرقبة، خلف الأذنين، الإبط، الأعضاء التناسلية، الأرداف، القدمين، أي طيات جلدية (للأشخاص ذوي الوزن الزائد)'
      ]
    }
  },
  {
    id: 'hygiene-full',
    category: 'skills',
    title: {
      en: 'Basic Hygiene – Fully Dependent',
      my: 'အခြေခံ တစ်ကိုယ်ရေသန့်ရှင်းရေး - အပြည့်အဝ မှီခိုသူ',
      th: 'สุขอนามัยพื้นฐาน – พึ่งพาเต็มที่',
      ar: 'النظافة الأساسية - معتمد كلياً'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    items: {
      en: [
        'Sponging in bed',
        'Observation and Treatment of Pressure Areas/Sores',
        'Changing of Bed Linen/Diapers/Clothes'
      ],
      my: [
        'အိပ်ရာပေါ်တွင် ရေပတ်တိုက်ပေးခြင်း',
        'ဖိအားကြောင့်ဖြစ်သော အနာများကို စောင့်ကြည့်ခြင်းနှင့် ကုသခြင်း',
        'အိပ်ရာခင်း/ဒိုင်ဘာ/အဝတ်အစားများ လဲလှယ်ခြင်း'
      ],
      th: [
        'การเช็ดตัวบนเตียง',
        'การสังเกตและการรักษาบริเวณที่กดทับ/แผลกดทับ',
        'การเปลี่ยนผ้าปูที่นอน/ผ้าอ้อม/เสื้อผ้า'
      ],
      ar: [
        'التنظيف بالإسفنج في السرير',
        'مراقبة وعلاج مناطق الضغط/التقرحات',
        'تغيير بياضات السرير/الحفاضات/الملابس'
      ]
    }
  },
  {
    id: 'bed-bathing-prep',
    category: 'skills',
    title: {
      en: 'Bed Bathing – Preparation',
      my: 'အိပ်ရာပေါ်တွင် ရေချိုးပေးခြင်း - ပြင်ဆင်မှု',
      th: 'การอาบน้ำบนเตียง – การเตรียมตัว',
      ar: 'الاستحمام في السرير - التحضير'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    items: {
      en: [
        'Essential Toiletries (soap, cologne, powder)',
        'Two basins',
        'Two face towels',
        'Two towels',
        'Bed linen',
        'Toilet paper or wet napkins (for cleaning soiled areas)',
        'Disposable diapers (optional)',
        'Disposable bag for soiled diapers & cleaning material'
      ],
      my: [
        'မရှိမဖြစ်လိုအပ်သော အသုံးအဆောင်များ (ဆပ်ပြာ၊ ရေမွှေး၊ ပေါင်ဒါ)',
        'ဇလုံ နှစ်ခု',
        'မျက်နှာသုတ်ပုဝါ နှစ်ထည်',
        'တဘက် နှစ်ထည်',
        'အိပ်ရာခင်း',
        'အိမ်သာသုံးစက္ကူ သို့မဟုတ် တစ်ရှူးအစို (ညစ်ပတ်သောနေရာများ သန့်ရှင်းရန်)',
        'တစ်ခါသုံး ဒိုင်ဘာ (ရွေးချယ်နိုင်သည်)',
        'ညစ်ပတ်သော ဒိုင်ဘာနှင့် သန့်ရှင်းရေးပစ္စည်းများ ထည့်ရန် တစ်ခါသုံးအိတ်'
      ],
      th: [
        'ของใช้ส่วนตัวที่จำเป็น (สบู่, โคโลญ, แป้ง)',
        'กะละมังสองใบ',
        'ผ้าเช็ดหน้าสองผืน',
        'ผ้าเช็ดตัวสองผืน',
        'ผ้าปูที่นอน',
        'กระดาษชำระหรือผ้าเช็ดทำความสะอาดแบบเปียก (สำหรับทำความสะอาดบริเวณที่สกปรก)',
        'ผ้าอ้อมสำเร็จรูป (ทางเลือก)',
        'ถุงพลาสติกสำหรับใส่ผ้าอ้อมที่ใช้แล้วและวัสดุทำความสะอาด'
      ],
      ar: [
        'مستلزمات النظافة الأساسية (صابون، كولونيا، بودرة)',
        'حوضان',
        'منشفتان للوجه',
        'منشفتان',
        'بياضات السرير',
        'ورق تواليت أو مناديل مبللة (لتنظيف المناطق المتسخة)',
        'حفاضات يمكن التخلص منها (اختياري)',
        'كيس يمكن التخلص منه للحفاضات المتسخة ومواد التنظيف'
      ]
    }
  },
  {
    id: 'bed-bathing-proc',
    category: 'skills',
    title: {
      en: 'Bed Bathing Procedures',
      my: 'အိပ်ရာပေါ်တွင် ရေချိုးပေးခြင်း လုပ်ငန်းစဉ်များ',
      th: 'ขั้นตอนการอาบน้ำบนเตียง',
      ar: 'إجراءات الاستحمام في السرير'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    items: {
      en: [
        'Inform the person that you are giving them a bath',
        'Turn off the fan to prevent chill',
        'Cover them with a towel and remove their clothes',
        'Wash their face and upper part of their body using a soaped face towel',
        'Wash their two legs',
        'Turn them to one side and wash their back',
        'Turn them on their back and give them the wet napkin to clean their genitalia',
        'Dry them with a towel',
        'Apply thin layer of moisturizer to dry skin if needed',
        'Dress them up & change their bed sheet',
        'Make them comfortable, prop them up & comb their hair',
        'Wash their hair if needed',
        'While washing, pay attention to: Eyes, Ears, Nose, Lips, Armpits, Groin, Genitalia, Skin Folds',
        'Look out for abnormalities and seek medical advice'
      ],
      my: [
        'ရေချိုးပေးမည်ဖြစ်ကြောင်း ကာယကံရှင်အား အသိပေးပါ',
        'အအေးမိခြင်းမှ ကာကွယ်ရန် ပန်ကာကို ပိတ်ပါ',
        'တဘက်ဖြင့် ဖုံးအုပ်ပြီး အဝတ်အစားများကို ချွတ်ပါ',
        'ဆပ်ပြာဆွတ်ထားသော မျက်နှာသုတ်ပုဝါဖြင့် မျက်နှာနှင့် ခန္ဓာကိုယ်အထက်ပိုင်းကို ဆေးကြောပါ',
        'ခြေထောက်နှစ်ဖက်ကို ဆေးကြောပါ',
        'ဘေးစောင်းလှည့်ပြီး ကျောကို ဆေးကြောပါ',
        'ပက်လက်လှန်ပြီး လိင်အင်္ဂါကို သန့်ရှင်းရန် တစ်ရှူးအစို ပေးပါ',
        'တဘက်ဖြင့် ခြောက်သွေ့အောင် သုတ်ပါ',
        'လိုအပ်ပါက ခြောက်သွေ့သော အရေပြားပေါ်တွင် အစိုဓာတ်ထိန်းခရင်မ် ပါးပါးလိမ်းပါ',
        'အဝတ်အစားဝတ်ပေးပြီး အိပ်ရာခင်းလဲပါ',
        'သက်တောင့်သက်သာရှိစေရန် လုပ်ဆောင်ပေးပါ၊ ထူမပေးပြီး ဆံပင်ဖြီးပေးပါ',
        'လိုအပ်ပါက ဆံပင်လျှော်ပေးပါ',
        'ဆေးကြောစဉ် ဂရုစိုက်ရမည့် နေရာများ - မျက်လုံး၊ နား၊ နှာခေါင်း၊ နှုတ်ခမ်း၊ ဂျိုင်း၊ ပေါင်ခြံ၊ လိင်အင်္ဂါ၊ အရေပြား ခေါက်နေသော နေရာများ',
        'ပုံမှန်မဟုတ်သော အခြေအနေများကို စစ်ဆေးပြီး ဆေးဘက်ဆိုင်ရာ အကူအညီရယူပါ'
      ],
      th: [
        'แจ้งให้บุคคลนั้นทราบว่าคุณกำลังจะอาบน้ำให้',
        'ปิดพัดลมเพื่อป้องกันความหนาวเย็น',
        'คลุมด้วยผ้าเช็ดตัวและถอดเสื้อผ้าออก',
        'ล้างหน้าและส่วนบนของร่างกายโดยใช้ผ้าเช็ดหน้าที่ชุบสบู่',
        'ล้างขาทั้งสองข้าง',
        'พลิกตัวไปด้านข้างและล้างหลัง',
        'พลิกตัวกลับมาและให้ผ้าเช็ดทำความสะอาดแบบเปียกเพื่อทำความสะอาดอวัยวะเพศ',
        'เช็ดให้แห้งด้วยผ้าเช็ดตัว',
        'ทามอยส์เจอไรเซอร์บางๆ บนผิวที่แห้งหากจำเป็น',
        'แต่งตัวและเปลี่ยนผ้าปูที่นอน',
        'ทำให้พวกเขารู้สึกสบาย พยุงตัวขึ้นและหวีผม',
        'สระผมหากจำเป็น',
        'ขณะล้าง ให้ความสนใจกับ: ตา, หู, จมูก, ริมฝีปาก, รักแร้, ขาหนีบ, อวัยวะเพศ, รอยพับของผิวหนัง',
        'สังเกตความผิดปกติและไปพบแพทย์'
      ],
      ar: [
        'أخبر الشخص أنك ستقوم بتحميمه',
        'أوقف تشغيل المروحة لمنع الشعور بالبرد',
        'قم بتغطيته بمنشفة واخلع ملابسه',
        'اغسل وجهه والجزء العلوي من جسمه باستخدام منشفة وجه بها صابون',
        'اغسل ساقيه',
        'اقلبه على جانب واحد واغسل ظهره',
        'اقلبه على ظهره وأعطه المنديل المبلل لتنظيف أعضائه التناسلية',
        'جففه بمنشفة',
        'ضع طبقة رقيقة من المرطب على البشرة الجافة إذا لزم الأمر',
        'ألبسه وغير ملاءة السرير',
        'اجعله يشعر بالراحة، وادعمه ومشط شعره',
        'اغسل شعره إذا لزم الأمر',
        'أثناء الغسيل، انتبه إلى: العينين، الأذنين، الأنف، الشفاه، الإبطين، الفخذ، الأعضاء التناسلية، طيات الجلد',
        'ابحث عن أي تشوهات واطلب المشورة الطبية'
      ]
    }
  },
  {
    id: 'dressing-grooming',
    category: 'skills',
    title: {
      en: 'Dressing Up & Grooming',
      my: 'အဝတ်အစားဝတ်ဆင်ခြင်းနှင့် အလှပြင်ခြင်း',
      th: 'การแต่งตัวและการดูแลตัวเอง',
      ar: 'ارتداء الملابس والعناية بالمظهر'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    items: {
      en: [
        'Assist patient with clothing changes while maintaining dignity and comfort',
        'Assist patient to groom up, shaving his moustache & beard',
        'Comb their hair',
        'Allow the person to see themselves in the mirror and make them happy'
      ],
      my: [
        'ဂုဏ်သိက္ခာနှင့် သက်တောင့်သက်သာရှိမှုကို ထိန်းသိမ်းလျက် အဝတ်အစားလဲလှယ်ရာတွင် ကူညီပါ',
        'အလှပြင်ရာတွင် ကူညီပါ၊ နှုတ်ခမ်းမွေးနှင့် မုတ်ဆိတ်မွေး ရိတ်ပေးပါ',
        'ဆံပင်ဖြီးပေးပါ',
        'မှန်ထဲတွင် မိမိကိုယ်ကို ကြည့်ရှုခွင့်ပေးပြီး ပျော်ရွှင်စေရန် လုပ်ဆောင်ပေးပါ'
      ],
      th: [
        'ช่วยผู้ป่วยเปลี่ยนเสื้อผ้าโดยรักษาศักดิ์ศรีและความสะดวกสบาย',
        'ช่วยผู้ป่วยดูแลตัวเอง โกนหนวดและเครา',
        'หวีผมให้พวกเขา',
        'ให้บุคคลนั้นเห็นตัวเองในกระจกและทำให้พวกเขามีความสุข'
      ],
      ar: [
        'مساعدة المريض في تغيير الملابس مع الحفاظ على كرامته وراحته',
        'مساعدة المريض على العناية بمظهره، وحلاقة شاربه ولحيته',
        'تمشيط شعرهم',
        'السماح للشخص برؤية نفسه في المرآة وجعله سعيداً'
      ]
    }
  },
  {
    id: 'foot-care',
    category: 'skills',
    title: {
      en: 'Foot Care',
      my: 'ခြေထောက် စောင့်ရှောက်မှု',
      th: 'การดูแลเท้า',
      ar: 'العناية بالقدم'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    items: {
      en: [
        'Do it after a shower',
        'Use lukewarm water to soak the feet',
        'Use mild soap & rinse thoroughly',
        'Pat dry with a towel',
        'Check for any sores, broken skin, ingrown toenails, skin disease',
        'Trim the toenails',
        'Apply a moisturizer to dry and cracked heels',
        'Diabetics with any wounds on the foot should seek medical advice'
      ],
      my: [
        'ရေချိုးပြီးနောက် ပြုလုပ်ပါ',
        'ခြေထောက်စိမ်ရန် ရေနွေးနွေးကို အသုံးပြုပါ',
        'ဆပ်ပြာအပျော့စားကို အသုံးပြုပြီး သေချာစွာ ဆေးကြောပါ',
        'တဘက်ဖြင့် ခြောက်သွေ့အောင် သုတ်ပါ',
        'အနာများ၊ အရေပြား ပေါက်ပြဲခြင်း၊ ခြေသည်းစိုက်ခြင်း၊ အရေပြား ရောဂါများ ရှိမရှိ စစ်ဆေးပါ',
        'ခြေသည်းများကို ညှပ်ပါ',
        'ခြောက်သွေ့ပြီး ကွဲနေသော ဖနောင့်များအတွက် အစိုဓာတ်ထိန်းခရင်မ် လိမ်းပါ',
        'ဆီးချိုရောဂါသည်များ ခြေထောက်တွင် အနာဖြစ်ပါက ဆေးဘက်ဆိုင်ရာ အကူအညီရယူပါ'
      ],
      th: [
        'ทำหลังจากอาบน้ำ',
        'ใช้น้ำอุ่นแช่เท้า',
        'ใช้สบู่อ่อนๆ และล้างออกให้สะอาด',
        'ซับให้แห้งด้วยผ้าเช็ดตัว',
        'ตรวจสอบแผล, ผิวหนังแตก, เล็บขบ, โรคผิวหนัง',
        'ตัดเล็บเท้า',
        'ทามอยส์เจอไรเซอร์ที่ส้นเท้าที่แห้งและแตก',
        'ผู้ป่วยเบาหวานที่มีแผลที่เท้าควรไปพบแพทย์'
      ],
      ar: [
        'افعل ذلك بعد الاستحمام',
        'استخدم الماء الفاتر لنقع القدمين',
        'استخدم صابوناً معتدلاً واشطفه جيداً',
        'جفف بالتربيت بمنشفة',
        'تحقق من وجود أي تقرحات، تشقق الجلد، أظافر نامية للداخل، أمراض جلدية',
        'تقليم أظافر القدمين',
        'ضع مرطباً على الكعب الجاف والمتشقق',
        'يجب على مرضى السكري الذين يعانون من أي جروح في القدم طلب المشورة الطبية'
      ]
    }
  },
  {
    id: 'oral-care',
    category: 'skills',
    title: {
      en: 'Oral & Denture Care',
      my: 'ခံတွင်းနှင့် သွားတု စောင့်ရှောက်မှု',
      th: 'การดูแลช่องปากและฟันปลอม',
      ar: 'العناية بالفم وأطقم الأسنان'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
    items: {
      en: [
        'If conscious, prop up about 45°',
        'Use a soft toothbrush to prevent gum injury',
        'Use wet cloth or lemon glycerin sticks if the person cannot do it themselves',
        'Use chopstick with cotton wrap and wet with carbonated water to remove plaque and thrush',
        'DENTURES: Remove & rinse after every meal',
        'Brush it with toothpaste at least once a day',
        'Sterilize it in recommended solution',
        'Remove it every night & place it in a glass of water'
      ],
      my: [
        'သတိရှိပါက ၄၅ ဒီဂရီခန့် ထူမပေးပါ',
        'သွားဖုံးဒဏ်ရာမရစေရန် သွားတိုက်တံ အပျော့စားကို အသုံးပြုပါ',
        'ကိုယ်တိုင်မလုပ်နိုင်ပါက အဝတ်စို သို့မဟုတ် သံပုရာ ဂလစ်စရင်းတုတ်တံများကို အသုံးပြုပါ',
        'ချိုးနှင့် မှက္ခရုများကို ဖယ်ရှားရန် ဂွမ်းပတ်ထားသော တူကို ကာဗွန်နိတ်ရေဆွတ်၍ အသုံးပြုပါ',
        'သွားတု - အစာစားပြီးတိုင်း ဖြုတ်၍ ဆေးကြောပါ',
        'တစ်နေ့လျှင် အနည်းဆုံး တစ်ကြိမ် သွားတိုက်ဆေးဖြင့် တိုက်ပါ',
        'အကြံပြုထားသော ပိုးသတ်ဆေးရည်ဖြင့် ပိုးသတ်ပါ',
        'ညတိုင်း ဖြုတ်၍ ရေခွက်ထဲတွင် ထည့်ထားပါ'
      ],
      th: [
        'หากรู้สึกตัว ให้พยุงขึ้นประมาณ 45°',
        'ใช้แปรงสีฟันขนนุ่มเพื่อป้องกันการบาดเจ็บที่เหงือก',
        'ใช้ผ้าเปียกหรือแท่งกลีเซอรีนเลมอนหากบุคคลนั้นไม่สามารถทำเองได้',
        'ใช้ตะเกียบพันสำลีชุบน้ำอัดลมเพื่อขจัดคราบจุลินทรีย์และเชื้อรา',
        'ฟันปลอม: ถอดและล้างหลังอาหารทุกมื้อ',
        'แปรงด้วยยาสีฟันอย่างน้อยวันละครั้ง',
        'ฆ่าเชื้อในน้ำยาที่แนะนำ',
        'ถอดออกทุกคืนและแช่ในแก้วน้ำ'
      ],
      ar: [
        'إذا كان واعياً، ادعمه بزاوية 45 درجة تقريباً',
        'استخدم فرشاة أسنان ناعمة لمنع إصابة اللثة',
        'استخدم قطعة قماش مبللة أو أعواد الجلسرين بالليمون إذا كان الشخص لا يستطيع القيام بذلك بنفسه',
        'استخدم عود طعام ملفوف بقطن ومبلل بمياه غازية لإزالة البلاك والفطريات',
        'أطقم الأسنان: قم بإزالتها وشطفها بعد كل وجبة',
        'نظفها بمعجون الأسنان مرة واحدة على الأقل يومياً',
        'عقمها في المحلول الموصى به',
        'قم بإزالتها كل ليلة وضعها في كوب من الماء'
      ]
    }
  },
  {
    id: 'constipation',
    category: 'skills',
    title: {
      en: 'Constipation',
      my: 'ဝမ်းချုပ်ခြင်း',
      th: 'อาการท้องผูก',
      ar: 'الإمساك'
    },
    videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    items: {
      en: [
        'May be due to: Inactivity',
        'Unbalanced diet',
        'Insufficient fruits & vegetables'
      ],
      my: [
        'အကြောင်းရင်းများ - လှုပ်ရှားမှုနည်းခြင်း',
        'မျှတမှုမရှိသော အစားအစာ',
        'သစ်သီးနှင့် ဟင်းသီးဟင်းရွက် စားသုံးမှု မလုံလောက်ခြင်း'
      ],
      th: [
        'อาจเกิดจาก: การไม่ค่อยเคลื่อนไหว',
        'อาหารที่ไม่สมดุล',
        'ผักและผลไม้ไม่เพียงพอ'
      ],
      ar: [
        'قد يكون بسبب: قلة النشاط',
        'نظام غذائي غير متوازن',
        'عدم كفاية الفواكه والخضروات'
      ]
    }
  }
];

export default function GuidanceView({ lang }: { lang: Language }) {
  const t = useTranslation(lang);
  const [selectedModule, setSelectedModule] = useState<Module | null>(null);

  const groupedModules = {
    theory: modules.filter(m => m.category === 'theory'),
    practical: modules.filter(m => m.category === 'practical'),
    skills: modules.filter(m => m.category === 'skills'),
  };

  const categories = [
    { id: 'theory', title: t('categoryTheory'), items: groupedModules.theory },
    { id: 'practical', title: t('categoryPractical'), items: groupedModules.practical },
    { id: 'skills', title: t('categorySkills'), items: groupedModules.skills },
  ];

  if (selectedModule) {
    return (
      <div className="p-4 max-w-md mx-auto pb-24">
        <button 
          onClick={() => setSelectedModule(null)}
          className="text-indigo-600 font-semibold mb-6 flex items-center bg-white/50 backdrop-blur-md px-3 py-1.5 rounded-full w-fit hover:bg-white transition-colors"
        >
          <ChevronRight className="w-5 h-5 rotate-180 mr-1" />
          {t('back')}
        </button>
        
        <h2 className="text-3xl font-bold tracking-tight text-slate-800 mb-6">
          {selectedModule.title[lang] || selectedModule.title['en']}
        </h2>

        {selectedModule.videoUrl && (
          <VideoPlayer 
            url={selectedModule.videoUrl} 
            poster={`https://picsum.photos/seed/${selectedModule.id}/800/450`} 
          />
        )}

        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white">
          <ul className="space-y-4">
            {(selectedModule.items[lang] || selectedModule.items['en']).map((item, idx) => (
              <li key={idx} className="flex items-start gap-3 text-slate-700">
                <CheckCircle2 className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" />
                <span className="leading-relaxed">{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4 max-w-md mx-auto pb-24">
      <div className="mb-6">
        <h2 className="text-3xl font-bold tracking-tight text-slate-800 mb-2">{t('guidance')}</h2>
      </div>

      <div className="bg-indigo-600 rounded-3xl p-6 text-white mb-8 shadow-lg shadow-indigo-200">
        <h3 className="font-bold text-xl mb-2">{t('ourAim')}</h3>
        <p className="text-indigo-100 leading-relaxed">
          {t('aimDescription')}
        </p>
      </div>

      <div className="space-y-8">
        {categories.map(cat => cat.items.length > 0 && (
          <div key={cat.id} className="space-y-3">
            <h3 className="text-xl font-bold text-slate-800 ml-2">{cat.title}</h3>
            {cat.items.map((mod) => (
              <div 
                key={mod.id}
                onClick={() => setSelectedModule(mod)}
                className="bg-white/80 backdrop-blur-xl p-5 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-white flex items-center justify-between cursor-pointer hover:shadow-[0_8px_30px_rgb(0,0,0,0.08)] hover:scale-[1.02] transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-indigo-50 to-purple-50 flex items-center justify-center shrink-0 text-indigo-600 shadow-inner border border-white">
                    <PlayCircle className="w-6 h-6" />
                  </div>
                  <p className="font-semibold text-slate-900 text-lg leading-tight">
                    {mod.title[lang] || mod.title['en']}
                  </p>
                </div>
                <ChevronRight className="w-5 h-5 text-slate-400 shrink-0" />
              </div>
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

function VideoPlayer({ url, poster }: { url: string; poster: string }) {
  const [isLoading, setIsLoading] = useState(true);

  return (
    <div className="relative mb-6 rounded-3xl overflow-hidden shadow-[0_8px_30px_rgb(0,0,0,0.08)] border border-white/50 bg-black aspect-video">
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center bg-black/40 backdrop-blur-[2px] z-10 transition-opacity duration-300 pointer-events-none">
          <Loader2 className="w-10 h-10 text-white animate-spin opacity-90" />
        </div>
      )}
      <video 
        controls 
        className="w-full h-full"
        poster={poster}
        onLoadStart={() => setIsLoading(true)}
        onCanPlay={() => setIsLoading(false)}
        onWaiting={() => setIsLoading(true)}
        onPlaying={() => setIsLoading(false)}
      >
        <source src={url} type="video/mp4" />
        Your browser does not support the video tag.
      </video>
    </div>
  );
}
