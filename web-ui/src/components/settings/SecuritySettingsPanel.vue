<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { toast } from '@/components/ui/toast'
import { ShieldCheck, AlertTriangle, KeyRound, User } from 'lucide-vue-next'
import { getSecuritySettings, updatePassword } from '@/api/settings'

const { t } = useI18n()

const username = ref('admin')
const isDefaultPassword = ref(false)
const currentPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const isLoading = ref(false)
const isSaving = ref(false)

async function fetchSecurityInfo() {
  isLoading.value = true
  try {
    const data = await getSecuritySettings()
    username.value = data.username
    isDefaultPassword.value = data.is_default_password
  } catch (e) {
    console.error('Failed to fetch security settings', e)
  } finally {
    isLoading.value = false
  }
}

async function handleSave() {
  if (!currentPassword.value) {
    toast({ title: t('settings.security.currentRequired'), variant: 'destructive' })
    return
  }
  if (!newPassword.value || newPassword.value.length < 4) {
    toast({ title: t('settings.security.newRequired'), variant: 'destructive' })
    return
  }
  if (newPassword.value !== confirmPassword.value) {
    toast({ title: t('settings.security.passwordMismatch'), variant: 'destructive' })
    return
  }

  isSaving.value = true
  try {
    const res = await updatePassword({
      username: username.value,
      current_password: currentPassword.value,
      new_password: newPassword.value,
      confirm_password: confirmPassword.value,
    })
    toast({
      title: t('settings.security.saved'),
      description: res.message,
    })
    currentPassword.value = ''
    newPassword.value = ''
    confirmPassword.value = ''
    isDefaultPassword.value = false
    // 更新本地用户名缓存
    localStorage.setItem('auth_username', username.value)
  } catch (e) {
    toast({
      title: t('settings.security.saveFailed'),
      description: (e as Error).message,
      variant: 'destructive',
    })
  } finally {
    isSaving.value = false
  }
}

onMounted(() => {
  fetchSecurityInfo()
})
</script>

<template>
  <Card class="app-surface overflow-hidden border-none shadow-sm">
    <CardHeader class="pb-4">
      <div class="flex items-center gap-3">
        <div class="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary">
          <KeyRound class="w-5 h-5" />
        </div>
        <div>
          <CardTitle class="text-lg font-bold text-slate-800">{{ t('settings.security.title') }}</CardTitle>
          <CardDescription class="text-sm text-slate-500">{{ t('settings.security.description') }}</CardDescription>
        </div>
      </div>
    </CardHeader>

    <CardContent class="space-y-6 pt-2">
      <!-- 初始默认密码安全告警 -->
      <div
        v-if="isDefaultPassword"
        class="flex items-start gap-3 p-4 rounded-xl bg-amber-50 border border-amber-200/80 text-amber-800 text-sm"
      >
        <AlertTriangle class="w-5 h-5 text-amber-500 shrink-0 mt-0.5" />
        <div>
          <span class="font-bold">安全提醒：</span>
          {{ t('settings.security.defaultWarning') }}
        </div>
      </div>

      <div class="grid gap-5 max-w-xl">
        <!-- 管理员用户名 -->
        <div class="grid gap-2">
          <Label class="text-sm font-semibold text-slate-700 flex items-center gap-1.5">
            <User class="w-4 h-4 text-slate-400" />
            {{ t('settings.security.username') }}
          </Label>
          <Input
            v-model="username"
            type="text"
            placeholder="admin"
            class="rounded-xl border-slate-200 bg-white"
          />
        </div>

        <!-- 当前密码 -->
        <div class="grid gap-2">
          <Label class="text-sm font-semibold text-slate-700 flex items-center gap-1.5">
            <KeyRound class="w-4 h-4 text-slate-400" />
            {{ t('settings.security.currentPassword') }}
          </Label>
          <Input
            v-model="currentPassword"
            type="password"
            placeholder="••••••••"
            class="rounded-xl border-slate-200 bg-white"
          />
        </div>

        <!-- 新密码 -->
        <div class="grid gap-2">
          <Label class="text-sm font-semibold text-slate-700">
            {{ t('settings.security.newPassword') }}
          </Label>
          <Input
            v-model="newPassword"
            type="password"
            placeholder="••••••••"
            class="rounded-xl border-slate-200 bg-white"
          />
        </div>

        <!-- 确认新密码 -->
        <div class="grid gap-2">
          <Label class="text-sm font-semibold text-slate-700">
            {{ t('settings.security.confirmPassword') }}
          </Label>
          <Input
            v-model="confirmPassword"
            type="password"
            placeholder="••••••••"
            class="rounded-xl border-slate-200 bg-white"
          />
        </div>
      </div>
    </CardContent>

    <CardFooter class="border-t border-slate-100 bg-slate-50/50 px-6 py-4 flex items-center justify-between">
      <p class="text-xs text-slate-400 flex items-center gap-1">
        <ShieldCheck class="w-4 h-4 text-emerald-500" />
        修改后将立即写入配置文件并生效
      </p>
      <Button
        @click="handleSave"
        :disabled="isSaving"
        class="rounded-xl shadow-sm px-6"
      >
        {{ isSaving ? t('settings.security.saving') : t('settings.security.save') }}
      </Button>
    </CardFooter>
  </Card>
</template>
