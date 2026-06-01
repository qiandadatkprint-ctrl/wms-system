<template>
  <!-- Floating help button -->
  <div class="tutorial-help-button" @click="openDrawer">
    <el-badge :value="tutorialSteps.length" :hidden="!tutorialSteps.length" class="help-badge">
      <el-button type="primary" circle size="large" class="help-circle-btn">
        <el-icon :size="24">
          <QuestionFilled />
        </el-icon>
      </el-button>
    </el-badge>
    <span class="help-label">教程</span>
  </div>

  <!-- Tutorial drawer panel -->
  <el-drawer
    v-model="drawerVisible"
    :title="currentTutorial?.title || '帮助指南'"
    direction="rtl"
    size="500px"
    :before-close="handleClose"
    custom-class="tutorial-drawer"
  >
    <template #header>
      <div class="drawer-header">
        <el-icon :size="22" color="#409EFF"><Reading /></el-icon>
        <span class="drawer-title">{{ currentTutorial?.title || '帮助指南' }}</span>
        <el-tag v-if="currentPath" size="small" type="info" effect="plain">
          {{ currentPath === '/' ? '/dashboard' : currentPath }}
        </el-tag>
      </div>
    </template>

    <!-- Tutorial content area -->
    <div v-if="currentTutorial" class="tutorial-content">
      <!-- Steps visualization -->
      <el-steps
        :active="activeStep"
        direction="vertical"
        process-status="process"
        finish-status="success"
        class="tutorial-steps"
      >
        <el-step
          v-for="(step, index) in tutorialSteps"
          :key="index"
          :title="step.title"
          :status="index === activeStep ? 'process' : index < activeStep ? 'success' : undefined"
          @click="activeStep = index"
        >
          <template #description>
            <div class="step-description" @click="activeStep = index">
              {{ step.content }}
            </div>
          </template>
        </el-step>
      </el-steps>

      <!-- Current step detail card -->
      <transition name="el-fade-in" mode="out-in">
        <el-card v-if="tutorialSteps[activeStep]" class="step-detail-card" shadow="hover">
          <template #header>
            <div class="step-detail-header">
              <span class="step-number">步骤 {{ activeStep + 1 }}</span>
              <span class="step-name">{{ tutorialSteps[activeStep].title }}</span>
            </div>
          </template>

          <div class="step-detail-content">
            <el-alert
              :title="tutorialSteps[activeStep].content"
              type="info"
              :closable="false"
              show-icon
            />

            <!-- Screenshot description placeholder -->
            <div v-if="tutorialSteps[activeStep].screenshot" class="screenshot-block">
              <div class="screenshot-placeholder">
                <el-icon :size="40" color="#c0c4cc"><PictureFilled /></el-icon>
                <p>{{ tutorialSteps[activeStep].screenshot }}</p>
              </div>
            </div>

            <!-- Pro tip -->
            <el-divider content-position="left">
              <el-text type="primary" size="small">操作提示</el-text>
            </el-divider>
            <el-text size="small" type="info">
              {{ getProTip(currentPath, activeStep) }}
            </el-text>
          </div>

          <!-- Step navigation -->
          <div class="step-navigation">
            <el-button
              type="primary"
              :disabled="activeStep === 0"
              @click="activeStep--"
              size="small"
              plain
            >
              <el-icon><ArrowLeft /></el-icon>
              上一步
            </el-button>
            <el-text size="small" type="info">
              {{ activeStep + 1 }} / {{ tutorialSteps.length }}
            </el-text>
            <el-button
              type="primary"
              :disabled="activeStep >= tutorialSteps.length - 1"
              @click="activeStep++"
              size="small"
            >
              下一步
              <el-icon><ArrowRight /></el-icon>
            </el-button>
          </div>
        </el-card>
      </transition>
    </div>

    <!-- Empty state: no tutorial for current route -->
    <el-empty
      v-else
      description="当前页面暂无教程"
      :image-size="120"
    >
      <template #default>
        <el-text type="info" size="small">
          导航到其他功能页面（如仓库管理、入库管理、物料管理等）可查看对应教程
        </el-text>
      </template>
    </el-empty>

    <!-- Quick navigation sidebar within drawer -->
    <template v-if="currentTutorial">
      <el-divider />
      <div class="quick-nav-section">
        <el-text size="small" type="info" class="quick-nav-title">快速跳转</el-text>
        <div class="quick-nav-buttons">
          <el-button
            v-for="(_, route) in visibleTutorials"
            :key="route"
            :type="isActiveRoute(route) ? 'primary' : 'default'"
            size="small"
            :plain="!isActiveRoute(route)"
            round
            @click="goToRoute(route)"
          >
            {{ tutorials[route].titleShort }}
          </el-button>
        </div>
      </div>
    </template>
  </el-drawer>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import {
  QuestionFilled,
  Reading,
  ArrowLeft,
  ArrowRight,
  PictureFilled
} from '@element-plus/icons-vue'

// ============================================================
// Route hooks
// ============================================================

const route = useRoute()
const router = useRouter()

// ============================================================
// Tutorial data: organized by route prefix
// ============================================================

const tutorials: Record<string, TutorialDefinition> = {
  '/dashboard': {
    title: '工作台使用指南',
    titleShort: '工作台',
    steps: [
      {
        title: '概览',
        content: '工作台展示仓库核心数据：物料数量、库存总量、待处理单据、预警信息。通过卡片快速了解仓库运行状态。',
        screenshot: '工作台概览页面截图：顶部为统计卡片区（物料数量、库存总量、待处理单据数、预警信息数），下方为快捷操作按钮和预警卡片组。'
      },
      {
        title: '快捷操作',
        content: '点击下方快捷按钮可快速进入入库、出库、盘点等常用功能，无需从左侧菜单逐级查找。',
        screenshot: '快捷操作区域截图：横向排列的快捷按钮包括「入库管理」「出库管理」「盘点管理」「移库管理」「库存查询」。'
      },
      {
        title: '实时监控',
        content: '库存预警卡片会高亮显示异常物料。红色表示库存过低需补货，黄色表示库存过高需处理。',
        screenshot: '预警卡片列表截图：左侧红色边框卡片显示库存过低物料，右侧橙色边框卡片显示库存过高物料，每张卡片包含物料名称、当前库存、安全库存和操作按钮。'
      },
    ]
  },
  '/warehouses': {
    title: '仓库库位管理指南',
    titleShort: '仓库管理',
    steps: [
      {
        title: '仓库层级',
        content: '系统采用 仓库→库区→库位 三级结构。先创建仓库，再在仓库下划分库区（存储区/拣货区/退货区/待检区），最后在库区下设置具体库位。',
        screenshot: '仓库层级结构图：仓库W-001「主仓库」→ 多个库区（LA-001存储区、LA-002拣货区）→ 每个库区下多个库位（LOC-001 A-01-01、LOC-002 A-01-02）。'
      },
      {
        title: '创建仓库',
        content: '点击"新增仓库"按钮，填写仓库编码（如WH-001）和名称。编码全局唯一，建议使用有规律的编号体系。',
        screenshot: '新增仓库弹窗截图：表单包含仓库编码输入框（带唯一性校验提示）、仓库名称输入框、仓库类型下拉选择（普通仓/冷藏仓/危化品仓）、备注文本域。'
      },
      {
        title: '管理库位',
        content: '点击仓库行的"查看库区"进入库区列表，再点击"查看库位"进入库位详情。每个库位可设置容量上限，超过上限入库时会提示。',
        screenshot: '库位列表页截图：表格显示库位编码、所属库区、容量上限、当前库存量、状态（启用/禁用），右侧操作列包含「编辑」「启用/禁用」「删除」按钮。'
      },
    ]
  },
  '/products': {
    title: '物料管理指南',
    titleShort: '物料管理',
    steps: [
      {
        title: 'SKU编码规则',
        content: '建议编码规则：分类缩写-序号。如 RM（原材料）、SF（半成品）、FP（成品）、PK（包装）、OF（办公）。系统已预置了15种示例物料供参考。',
        screenshot: '物料列表页截图：表格展示编码列（RM-001、SF-001、FP-001等），每条物料显示SKU编码、名称、分类、单位、安全库存、最大库存信息。'
      },
      {
        title: '条码管理',
        content: '条码字段用于扫码枪快速识别。USB扫码枪即插即用，将光标放在输入框内，扫描条码即可自动填入物料信息。',
        screenshot: '条码扫描操作示意图：鼠标光标聚焦在条码/编码输入框，扫码枪扫描物料条码后自动填充物料编码并带出名称、分类等关联信息。'
      },
      {
        title: '安全库存',
        content: '设置安全库存和最大库存后，系统会自动监控。当前库存低于安全库存或高于最大库存时会出现在预警页面。',
        screenshot: '物料编辑弹窗截图：安全库存和最大库存字段用橙色高亮标注，旁边有提示图标说明"低于安全库存将触发补货预警，高于最大库存将触发积压预警"。'
      },
      {
        title: '创建新物料',
        content: '点击"新增物料"填写信息。分类下拉可选择：原材料、半成品、成品、包装材料、办公用品。单位下拉可选：个、箱、包、kg、吨、米、升、根、台、套、卷、双。',
        screenshot: '新增物料弹窗截图：表单逐行展示编码输入框、名称输入框、分类下拉框（展开显示5个选项）、单位下拉框（展开显示12个计量单位选项）、条码输入框、安全库存/最大库存数字输入框。'
      },
    ]
  },
  '/inbound': {
    title: '入库管理指南',
    titleShort: '入库管理',
    steps: [
      {
        title: '创建入库单',
        content: '选择入库类型（采购入库/退货入库/其他入库）、关联供应商、目标仓库，然后添加入库明细行。每行选择物料、预期数量、建议上架库位。',
        screenshot: '创建入库单页面截图：顶部为表单区域（入库类型单选、供应商下拉、目标仓库下拉），下方为明细表格（物料选择、数量输入、建议库位展示），底部为保存/提交按钮。'
      },
      {
        title: '收货确认',
        content: '物料到达后，进入入库单详情页。逐行填写实收数量、分配实际库位、录入批次号和生产日期。系统已为每个物料预填了建议库位和批次号示例。',
        screenshot: '入库单详情-收货确认页截图：明细表格可编辑列（实收数量、实际库位、批次号、生产日期），每行有状态标签（待收货/已收货），底部「确认入库」按钮在实收数量全部填写后激活。'
      },
      {
        title: '确认入库',
        content: '点击"确认入库"按钮，系统将自动：① 更新对应库位库存 ② 写入库存流水记录 ③ 将入库单状态改为已完成。注意：确认后不可撤销。',
        screenshot: '确认入库操作示意图：点击按钮后弹出二次确认弹窗「确认后将更新库存且不可撤销，是否继续？」，确认后页面顶部显示绿色成功提示"入库单 WHIN-20240101-001 已确认入库"。'
      },
    ]
  },
  '/outbound': {
    title: '出库管理指南',
    titleShort: '出库管理',
    steps: [
      {
        title: '创建出库单',
        content: '选择出库类型（销售出库/领料出库/其他出库）、关联客户、出库仓库，添加出库明细。',
        screenshot: '创建出库单页面截图：顶部表单区域（出库类型单选按钮组、客户下拉选择、出库仓库下拉选择），下方出库明细表格（物料选择、申请数量输入），底部保存/提交按钮。'
      },
      {
        title: 'FIFO自动分配',
        content: '系统采用先进先出（FIFO）策略。点击"FIFO自动分配拣货方案"，系统按生产日期从早到晚自动匹配库存。缺货时会提示具体物料及缺少数。',
        screenshot: 'FIFO自动分配操作截图：点击按钮后明细表格自动填充「分配数量」「源库位」「批次号」列，缺货物料行显示红色「缺货 X 件」标签，顶部汇总显示可满足/缺货统计。'
      },
      {
        title: '确认出库',
        content: '拣货完成后点击"确认出库"，系统自动扣减库存并写入流水。同时检查是否触发安全库存预警。',
        screenshot: '确认出库操作示意图：二次确认弹窗，确认后页面跳转到出库单列表，该单状态更新为「已完成」，对应物料的库存流水新增一条出库记录。'
      },
    ]
  },
  '/stocktaking': {
    title: '盘点管理指南',
    titleShort: '盘点管理',
    steps: [
      {
        title: '盘点类型',
        content: '全盘：盘点仓库所有物料。抽盘：指定部分物料。动盘：仅盘点近期有库存变动的物料（7天内）。',
        screenshot: '创建盘点任务弹窗截图：盘点类型下拉（全盘/抽盘/动盘），仓库选择，盘点日期选择器。选择抽盘时出现物料多选框，选择动盘时显示时间范围提示。'
      },
      {
        title: '盘点流程',
        content: '① 创建盘点任务（系统自动生成当前库存明细）→ ② 盘点员实地清点并录入数量 → ③ 主管复核差异项 → ④ 确认调整库存。',
        screenshot: '盘点流程四步示意图：1-创建任务截图 2-盘点录入截图（表格实盘数量列可编辑） 3-差异复核截图（差异行高亮显示） 4-确认调整按钮截图。'
      },
      {
        title: '差异处理',
        content: '盘盈（实际>系统）自动增加库存；盘亏（实际<系统）自动扣减库存。所有调整都有流水记录可追溯。',
        screenshot: '盘点差异报告截图：差异对比表（物料名称、系统库存、实盘数量、差异数量、差异类型标签），底部汇总统计（盘盈X项、盘亏Y项），「确认调整」按钮。'
      },
    ]
  },
  '/transfers': {
    title: '移库管理指南',
    titleShort: '移库管理',
    steps: [
      {
        title: '移库操作',
        content: '选择物料后，系统自动显示该物料有库存的库位。选择源库位和目标库位，输入数量即可完成移库。',
        screenshot: '创建移库单页面截图：物料选择下拉（带搜索），选择后下方自动加载该物料的库存分布（表格显示库位+批次+库存量），源库位和目标库位下拉，数量输入框，保存按钮。'
      },
      {
        title: '注意事项',
        content: '① 源库位和目标库位不能相同 ② 移库数量不能超过源库位当前库存 ③ 移库会生成移出和移入两条流水记录。',
        screenshot: '移库验证提示截图：选择相同库位时红色错误提示"源库位和目标库位不能相同"；输入超量时红色提示"移库数量不能超过当前库存 X"。'
      },
    ]
  },
  '/inventory': {
    title: '库存查询指南',
    titleShort: '库存查询',
    steps: [
      {
        title: '库存视图',
        content: '按物料+库位+批次维度展示当前库存。支持按物料名称/编码/条码搜索。点击"查看流水"可进入详细流水页面。',
        screenshot: '库存查询页截图：顶部搜索栏（物料名称、编码、条码输入框，搜索按钮），下方库存表格（物料编码、名称、库位、批次、库存数量、操作-查看流水按钮）。'
      },
      {
        title: '库存流水',
        content: '所有库存变动（入库、出库、移库、盘点调整）均有流水记录。可按类型、时间范围筛选，支持追溯每一笔变动的来源单据。',
        screenshot: '库存流水页截图：筛选栏（流水类型下拉多选、时间范围选择器），流水表格（时间、类型标签、物料、库位、变动数量（+/-）、来源单号-可点击跳转、操作人）。'
      },
    ]
  },
  '/alerts': {
    title: '库存预警指南',
    titleShort: '库存预警',
    steps: [
      {
        title: '预警机制',
        content: '系统自动对比当前库存与安全库存/最大库存阈值。低于安全库存显示红色"库存过低"，高于最大库存显示橙色"库存过高"。',
        screenshot: '预警列表截图：预警卡片列表，红色边框卡片标题"库存过低-阀芯 RM-003"显示当前库存15低于安全库存50，橙色边框卡片标题"库存过高-密封圈 RM-008"显示当前库存1200高于最大库存1000。'
      },
      {
        title: '处理建议',
        content: '库存过低：建议尽快创建采购入库单补货。库存过高：建议暂停采购或创建出库单清理库存。',
        screenshot: '预警卡片详情截图：红色预警卡片展开后显示处理建议区域，蓝色链接「一键创建采购入库单」和「查看历史采购记录」；橙色预警卡片显示「创建出库单清理库存」链接。'
      },
    ]
  },
  '/suppliers': {
    title: '供应商管理指南',
    titleShort: '供应商',
    steps: [
      {
        title: '供应商信息',
        content: '记录供应商基本信息：编码、名称、联系人、电话、地址。编码建议使用SUP-序号格式。系统已预置5家示例供应商。',
        screenshot: '供应商列表页截图：表格显示编码（SUP-001~005）、名称、联系人、联系电话、地址列，操作列包含编辑和删除按钮。顶部有「新增供应商」按钮和搜索框。'
      },
    ]
  },
  '/customers': {
    title: '客户管理指南',
    titleShort: '客户',
    steps: [
      {
        title: '客户信息',
        content: '记录客户基本信息：编码、名称、联系人、电话、地址。编码建议使用CUS-序号格式。系统已预置5家示例客户。',
        screenshot: '客户列表页截图：表格显示编码（CUS-001~005）、名称、联系人、联系电话、地址列，操作列包含编辑和删除按钮。顶部有「新增客户」按钮和搜索框。'
      },
    ]
  },
  '/logs': {
    title: '操作日志指南',
    titleShort: '操作日志',
    steps: [
      {
        title: '审计追溯',
        content: '所有关键操作（登录、创建单据、确认出入库、盘点调整）均自动记录。可按操作人、操作类型、时间范围筛选。',
        screenshot: '操作日志页截图：筛选栏（操作人输入框、操作类型下拉多选、时间范围选择器），日志表格（时间、操作人、IP地址、操作类型标签、操作描述、关联单号）。'
      },
      {
        title: '安全合规',
        content: '日志数据只增不删，满足企业内部审计和合规要求。异常操作可快速定位到人和时间。',
        screenshot: '日志详情弹窗截图：展示单条日志的完整信息面板（操作时间、操作人、IP、操作类型、模块、操作前数据JSON、操作后数据JSON、请求ID）。'
      },
    ]
  },
}

// ============================================================
// Tutorial type definition
// ============================================================

interface TutorialStep {
  title: string
  content: string
  screenshot?: string
}

interface TutorialDefinition {
  title: string
  titleShort: string
  steps: TutorialStep[]
}

// ============================================================
// State
// ============================================================

const drawerVisible = ref(false)
const activeStep = ref(0)

// ============================================================
// Computed: current route matching
// ============================================================

const currentPath = computed(() => route.path)

const currentTutorial = computed(() => {
  const path = currentPath.value
  for (const key of Object.keys(tutorials)) {
    if (path === '/' && key === '/dashboard') return tutorials[key]
    if (path !== '/' && path.startsWith(key) && key !== '/dashboard') return tutorials[key]
    if (path !== '/' && path.startsWith(key) && key === '/dashboard') return tutorials[key]
  }
  return null
})

const tutorialSteps = computed(() => currentTutorial.value?.steps || [])

const visibleTutorials = computed(() => {
  // Show all main routes for quick navigation (exclude sub-routes like /inbound/123)
  return tutorials
})

// ============================================================
// Methods
// ============================================================

function openDrawer() {
  activeStep.value = 0
  drawerVisible.value = true
}

function handleClose(done: () => void) {
  activeStep.value = 0
  done()
}

function isActiveRoute(routeKey: string): boolean {
  const path = currentPath.value
  if (path === '/' && routeKey === '/dashboard') return true
  if (path !== '/' && path.startsWith(routeKey)) return true
  return false
}

function goToRoute(routeKey: string) {
  router.push(routeKey)
}

function getProTip(path: string, stepIndex: number): string {
  const tips: Record<string, Record<number, string>> = {
    '/dashboard': {
      0: '工作台是企业版首页，可在此页面快速掌握仓库全局状态，建议每次登录后先查看工作台。',
      1: '快捷按钮支持自定义排序，可在设置中根据使用频率调整按钮顺序。',
      2: '点击预警卡片可直接跳转到对应的处理页面，红色卡片跳转到入库创建页，橙色卡片跳转到出库创建页。',
    },
    '/warehouses': {
      0: '规划仓库层级时，建议先在纸上画出仓库平面图，再在系统中配置，避免频繁修改。',
      1: '仓库编码一旦创建不可修改，请务必提前规划好编码体系。',
      2: '库位编码建议包含区域和行列信息，如 A-01-01 表示A区第1排第1个货位，方便实地查找。',
    },
    '/products': {
      0: '好的SKU编码体系是WMS高效运转的基础，建议在系统上线前统一制定编码规范。',
      1: '扫码枪不需要安装任何驱动，Windows系统会自动识别为键盘输入设备。在Excel中确认扫码正常后再在系统中使用。',
      2: '安全库存值建议基于历史出库数据和采购周期计算，避免设置过低导致缺货或过高增加仓储成本。',
      3: '物料创建后编码不可修改，建议在正式录入前先在Excel中规划好所有物料清单再批量导入。',
    },
    '/inbound': {
      0: '入库类型选择直接影响后续的统计分析，务必准确选择。采购入库通常关联供应商和采购订单。',
      1: '批次号建议格式：供应商缩写+生产日期，如 SUP-A240101，方便后续按批次追溯。',
      2: '确认入库前请逐一核对实收数量与送货单一致，确认后数据无法回退修改（只能通过盘点调整）。',
    },
    '/outbound': {
      0: '出库类型影响成本和利润核算。销售出库会关联客户和销售订单，领料出库关联内部生产工单。',
      1: 'FIFO策略确保先生产的物料先出库，对于有保质期要求的物料尤为重要。系统会自动跳过过期批次。',
      2: '出库确认前建议打印拣货单让仓库人员核对实物，避免错发漏发。',
    },
    '/stocktaking': {
      0: '动盘效率最高，适合日常高频盘点。全盘建议在月末/季度末进行，抽盘适合针对高价值物料重点盘点。',
      1: '盘点过程中建议暂停出入库操作，确保盘点数据准确。系统支持锁定仓库模式，创建盘点任务时可选择。',
      2: '主管复核差异项是重要内控环节，建议设置为必审流程。差异超过一定比例（如5%）需二次确认。',
    },
    '/transfers': {
      0: '移库常用于库位整理和优化，建议定期分析库存分布，将热销物料调整到拣货区以提高出库效率。',
      1: '大批量移库建议分批操作，每批确认后检查库存准确性再继续。系统支持移库模板批量导入。',
    },
    '/inventory': {
      0: '库存查询支持导出Excel，方便做数据分析和报告。使用Ctrl+F可在导出文件中快速定位物料。',
      1: '流水数据建议定期归档（如每月导出备份），保证系统性能。流水查询时间范围建议不超过3个月。',
    },
    '/alerts': {
      0: '建议每天早上登录后首先查看预警页面，及时处理库存异常。可设置邮件/短信预警通知（需配置通知服务）。',
      1: '连续3天预警的物料会被标记为"重点关注"，建议加急处理。可在设置中调整预警级别和通知频率。',
    },
    '/suppliers': {
      0: '供应商信息应定期更新，建议每季度核实一次联系人信息。供应商评级功能需要开启后才可用。',
    },
    '/customers': {
      0: '客户信息属于敏感数据，建议设置访问权限。客户编码创建后不可删除，只能停用。',
    },
    '/logs': {
      0: '日志保留期建议不少于6个月，满足大部分审计要求。超过保留期的日志可归档到外部存储。',
      1: '发现异常操作时，可点击操作描述查看完整的操作前后数据对比，快速判断是否为误操作或恶意操作。',
    },
  }

  return tips[path]?.[stepIndex] || '按照步骤指引操作即可。如有疑问请联系系统管理员。'
}

// ============================================================
// Reset activeStep when route changes
// ============================================================

watch(currentPath, () => {
  activeStep.value = 0
})
</script>

<style scoped>
/* ============================================================
   Floating help button
   ============================================================ */

.tutorial-help-button {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 1000;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  transition: transform 0.3s ease;
}

.tutorial-help-button:hover {
  transform: scale(1.1);
}

.tutorial-help-button:active {
  transform: scale(0.95);
}

.help-circle-btn {
  width: 50px;
  height: 50px;
  background: linear-gradient(135deg, #409EFF, #337ecc) !important;
  border: none !important;
  box-shadow: 0 4px 14px rgba(64, 158, 255, 0.4);
  transition: box-shadow 0.3s ease, transform 0.3s ease;
}

.help-circle-btn:hover {
  box-shadow: 0 6px 20px rgba(64, 158, 255, 0.6);
}

.help-label {
  font-size: 12px;
  color: #909399;
  letter-spacing: 2px;
  user-select: none;
}

.help-badge {
  line-height: 1;
}

/* ============================================================
   Drawer header
   ============================================================ */

.drawer-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.drawer-title {
  font-size: 16px;
  font-weight: 600;
  color: #303133;
}

/* ============================================================
   Tutorial content area
   ============================================================ */

.tutorial-content {
  padding: 0 0 20px 0;
}

.tutorial-steps {
  margin-bottom: 24px;
}

.tutorial-steps :deep(.el-step__title) {
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: color 0.3s ease;
}

.tutorial-steps :deep(.el-step__title:hover) {
  color: #409EFF;
}

.tutorial-steps :deep(.el-step.is-process .el-step__title) {
  color: #409EFF;
}

.step-description {
  font-size: 13px;
  color: #606266;
  line-height: 1.7;
  cursor: pointer;
  padding: 4px 0;
  transition: color 0.3s ease;
}

.step-description:hover {
  color: #409EFF;
}

/* ============================================================
   Step detail card
   ============================================================ */

.step-detail-card {
  background: #fafcff;
  border: 1px solid #e4e7ed;
  border-radius: 8px;
}

.step-detail-header {
  display: flex;
  align-items: center;
  gap: 8px;
}

.step-number {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #409EFF, #66b1ff);
  color: #fff;
  font-size: 12px;
  font-weight: 600;
  padding: 2px 10px;
  border-radius: 12px;
}

.step-name {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.step-detail-content {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* ============================================================
   Screenshot placeholder
   ============================================================ */

.screenshot-block {
  margin-top: 4px;
}

.screenshot-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 20px;
  background: #f5f7fa;
  border: 1px dashed #dcdfe6;
  border-radius: 8px;
  gap: 8px;
}

.screenshot-placeholder p {
  margin: 0;
  font-size: 12px;
  color: #909399;
  text-align: center;
  line-height: 1.6;
}

/* ============================================================
   Step navigation buttons
   ============================================================ */

.step-navigation {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
}

/* ============================================================
   Quick navigation section
   ============================================================ */

.quick-nav-section {
  padding: 0 0 10px 0;
}

.quick-nav-title {
  display: block;
  margin-bottom: 10px;
  font-weight: 500;
}

.quick-nav-buttons {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

/* ============================================================
   Animations
   ============================================================ */

.tutorial-help-button {
  animation: helpPulse 2s ease-in-out infinite;
}

@keyframes helpPulse {
  0%, 100% {
    transform: scale(1);
  }
  50% {
    transform: scale(1.05);
  }
}

.tutorial-help-button:hover {
  animation: none;
}

/* ============================================================
   Custom drawer styles (deep selectors for Element Plus) */
/* ============================================================ */

:deep(.tutorial-drawer) {
  border-radius: 12px 0 0 12px;
}

:deep(.tutorial-drawer .el-drawer__header) {
  padding: 20px 24px 16px;
  margin-bottom: 0;
  border-bottom: 1px solid #ebeef5;
  background: linear-gradient(135deg, #f0f7ff 0%, #ffffff 100%);
}

:deep(.tutorial-drawer .el-drawer__body) {
  padding: 20px 24px;
}

:deep(.tutorial-drawer .el-drawer__close-btn) {
  font-size: 18px;
  color: #909399;
}

:deep(.tutorial-drawer .el-drawer__close-btn:hover) {
  color: #409EFF;
}

/* ============================================================
   Responsive adjustments
   ============================================================ */

@media (max-width: 576px) {
  .tutorial-help-button {
    bottom: 12px;
    right: 12px;
  }

  .help-circle-btn {
    width: 44px;
    height: 44px;
  }

  .tutorial-drawer {
    width: 100vw !important;
  }
}
</style>
