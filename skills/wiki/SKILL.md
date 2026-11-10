---
name: wiki
description: LLM Wiki 知识库的维护与问答 skill：ingest（消化 raw/ 新资料并增量更新 wiki 页面）、query（基于知识库回答问题并注明出处）、lint（健康检查：近重复页/矛盾/孤儿页/断链）、crystallize（把当前对话沉淀为 wiki 页面）。凡用户提到"整理知识库/消化资料/处理新资料/ingest"、"知识库问答/查 wiki/在笔记里找"、"健康检查/lint/检查知识库"、"把这次讨论沉淀/记入知识库"，或往 raw/ 放了新资料想让它进入知识库时，一律使用本 skill。即使没说"wiki"二字，只要意图是对当前知识库做整理、提问、体检，也应触发。
---

# /wiki — LLM Wiki 知识库操作

本 skill 驱动一个按 Karpathy LLM Wiki 模式运作的 Obsidian vault 知识库：

- `raw/` —— 用户供料的原始资料，LLM 只读
- `wiki/` —— LLM 生成与维护的互链页面（sources / entities / concepts / analyses + index/log/overview）
- `AGENTS.md` —— schema：结构、页面格式、维护纪律

**知识库根目录 = 当前工作目录**（或用户明确指出的目录）。本 skill 位置无关，可驱动任意机器上的任意知识库实例。

## 适用性检查

若当前目录没有 `AGENTS.md` 和 `wiki/`，说明这里不是 LLM Wiki 知识库——**不要凭空创建结构**。向用户说明情况；仅当用户明确要求新建知识库时，才按知识库的 schema 模板初始化（目录骨架与 AGENTS.md 模板见 ai-assets 仓库 `skills/wiki/` 的 README 部分）。

## 第 0 步（每次必做）

1. 读 `AGENTS.md` —— schema 与维护纪律，一切以它为准（本 skill 与它冲突时以它为准）
2. 读 `wiki/index.md`（内容目录）并看最近操作：`grep "^## \[" wiki/log.md | tail -5`
3. 按用户意图进入对应工作流

## ingest（消化资料）

触发："整理/消化知识库"、"处理 raw/ 的新资料"、定时任务。

1. **幂等检查**：`bash <本skill目录>/scripts/pending.sh .` → 列出 PENDING 的 raw 文件
2. 无 PENDING → 报告"没有未消化的新资料"，结束
3. **逐篇处理**（默认一篇一停：向用户汇报要点与拟建/拟改页面，确认侧重后继续；用户要求批量、或定时任务触发时连续执行）：
   a. 读原文全文（大文件分段读）
   b. 写 `wiki/sources/YYYY-MM-DD-slug.md`：按 schema 的 frontmatter 格式，含 `raw:` 路径与 `digest_sha256:`（用 `sha256sum raw/<file>` 计算）
   c. 更新受影响的 entity/concept 页：**先扩展后新建**（先查 index.md 并 grep，确认无近重复页）；更新已有摘要时**重写整合**，不做追加式流水账
   d. 新建页后，回填相关旧页与 `index.md` 中指向新页的链接（每页至少 2 个出链）
   e. 有沉淀价值的对比/综合 → `wiki/analyses/`
   f. 更新 `wiki/index.md`；若全局理解变化 → 更新 `wiki/overview.md`
4. `wiki/log.md` 追加：`## [YYYY-MM-DD] ingest | <资料名>`，列新建/更新的页面
5. `git commit -m "ingest: <资料名>"`（知识库应是 git 仓库）

## query（知识问答）

触发：任何想基于知识库回答的问题。

1. 读 `wiki/index.md` 定位相关页 → 再读页面细节
2. wiki 覆盖不足时才回读 `raw/` 原文，并在答案中注明"wiki 未覆盖，引自原文"
3. 回答注明出处（wikilink 页面 / raw 路径）；输出形态遵循 `wiki/conventions.md`（默认 markdown 正文；对比表、Marp 幻灯片、图表按用户点名产出）
4. 有沉淀价值的回答 → 归档 `wiki/analyses/` 并更新 index/log
5. `git commit -m "query: <问题摘要>"`

## lint（健康检查）

触发："检查知识库/健康检查/lint"，或 wiki 明显膨胀时。

逐项检查并产出报告：
1. **近重复页**（同一主题存在两页）→ 建议合并进更完整的一页
2. **矛盾/过时论断**（新源推翻旧说法但页面未更新）
3. **孤儿页**（无入链）——快查脚本见下
4. **被多处提及但没有页面的概念/实体**（建页候选）
5. **缺失交叉引用**（明显相关却互不链接的页面）
6. **index.md 与实际不一致**（漏列/死链）
7. 顺带跑 `pending.sh` 看是否有未消化资料

报告写入 `log.md`（`lint` 条目），逐项给修复建议，**经用户确认后**才执行修复。`git commit -m "lint: YYYY-MM-DD"`。

孤儿页快查（在知识库根目录执行）：

```bash
find wiki -name '*.md' -print0 | while IFS= read -r -d '' f; do
  case "$f" in */index.md|*/log.md) continue ;; esac
  base=$(basename "$f" .md)
  if ! grep -rlsF -- "[[$base]]" wiki | grep -vxF "$f" >/dev/null; then
    echo "ORPHAN: $f"
  fi
done
```

## crystallize（对话结晶）

触发："把这次讨论/结论沉淀到知识库"。

1. 提炼本次对话中有长期价值的结论、决定、新知识
2. 归档：对比→`analyses/`；新概念/实体→扩展对应旧页（没有就新建）；零散但有价值→新建 analysis 页
3. 更新 index/log；`git commit -m "crystallize: <主题>"`

## 关于定时自动化（按需配置）

ingest 是幂等的（SHA256 去重），适合定时跑。需要时用宿主 agent 的定时能力创建每日任务，提示词即："加载 wiki skill，在 <知识库路径> 执行 ingest 工作流，汇报结果"。
