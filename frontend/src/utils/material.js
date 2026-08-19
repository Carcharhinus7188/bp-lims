// 材料名称 + 样品名称 合并展示（去重，兼容旧数据两者相同的情况）
export function materialWithSample(materialName, sampleName) {
  const parts = [materialName, sampleName].filter((v) => v && String(v).trim())
  return [...new Set(parts)].join(' ')
}
