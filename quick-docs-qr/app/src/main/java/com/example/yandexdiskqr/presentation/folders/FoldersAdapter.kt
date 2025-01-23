package com.example.yandexdiskqr.presentation.folders

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.yandexdiskqr.data.model.YandexDiskFile
import com.example.yandexdiskqr.databinding.ItemFolderBinding

class FoldersAdapter(
    private val onFolderClick: (YandexDiskFile) -> Unit
) : ListAdapter<YandexDiskFile, FoldersAdapter.FolderViewHolder>(FolderDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): FolderViewHolder {
        val binding = ItemFolderBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return FolderViewHolder(binding)
    }

    override fun onBindViewHolder(holder: FolderViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    inner class FolderViewHolder(
        private val binding: ItemFolderBinding
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(folder: YandexDiskFile) {
            binding.folderName.text = folder.name
            binding.root.setOnClickListener { onFolderClick(folder) }
            binding.generateQrButton.setOnClickListener { onFolderClick(folder) }
        }
    }

    private class FolderDiffCallback : DiffUtil.ItemCallback<YandexDiskFile>() {
        override fun areItemsTheSame(oldItem: YandexDiskFile, newItem: YandexDiskFile): Boolean {
            return oldItem.path == newItem.path
        }

        override fun areContentsTheSame(oldItem: YandexDiskFile, newItem: YandexDiskFile): Boolean {
            return oldItem == newItem
        }
    }
}
