<template>
  <el-dropdown @visible-change="onChange" @command="handleCommand">
    <div class="avatar-dropdown">
      <img class="user-avatar" :src="avatarUrl || logoPng" alt="" />
      <div class="user-name">{{ name }}</div>
      <el-icon class="up-down">
        <component :is="visible ? 'ArrowUp' : 'ArrowDown'" />
      </el-icon>
    </div>
    <template #dropdown>
      <el-dropdown-menu>
        <el-dropdown-item command="logout">
          <!-- color为默认颜色 -->
          <svg-icon name="logout" size="16px" color="" />
          <span>退出登陆</span>
        </el-dropdown-item>
      </el-dropdown-menu>
    </template>
  </el-dropdown>
</template>

<script lang="ts">
import logoPngUrl from '@/assets/images/logo.png'
import { LOGIN_URL } from '@/config/config'
import { useUserStore } from '@/store/modules/user'
import { ArrowDown, ArrowUp } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { defineComponent, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
export default defineComponent({
  components: {
    ArrowUp,
    ArrowDown,
  },
  setup() {
    const logoPng = ref(logoPngUrl)
    const router = useRouter()
    const route = useRoute()
    const userStore = useUserStore()

    const { name, avatarUrl } = userStore.userInfo || {}
    const visible = ref(false)

    function onChange(show: boolean) {
      visible.value = show
    }

    function handleCommand(command: string) {
      if (command === 'logout') {
        logout()
      }
    }

    // 退出登陆
    function logout() {
      ElMessageBox.confirm('您确定要退出吗？', '提示', {
        confirmButtonText: '确认',
        cancelButtonText: '取消',
        type: 'warning',
      }).then(async () => {
        await userStore.Logout()
        router.push({ path: LOGIN_URL, query: { redirect: route.fullPath } })
        ElMessage.success('退出登录成功！')
      })
    }
    return {
      logoPng,
      name,
      avatarUrl,
      visible,
      onChange,
      handleCommand,
    }
  },
})
</script>

<style scoped lang="scss">
.avatar-dropdown {
  display: flex;
  align-content: center;
  align-items: center;
  justify-content: center;
  justify-items: center;
  height: 50px;
  padding: 0;

  .user-avatar {
    width: 40px;
    height: 40px;
    cursor: pointer;
    border-radius: 50%;
  }

  .user-name {
    position: relative;
    margin: 0 6px;
    cursor: pointer;
  }
}
/* 解决按钮黑边框bug */
:deep(:focus) {
  outline: 0;
}
</style>
